// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IProjectRegistry {
    function getProject(uint256 projectId) external view returns (
        uint256 id,
        address owner,
        string memory name,
        string memory descriptionCID,
        string memory category,
        bool isActive
    );
}

contract QuadraticFunding is Ownable {
    // Events
    event ContributionMade(address indexed contributor, uint256 indexed projectId, uint256 amount);
    event MatchingFundsDistributed(uint256 totalMatching, uint256 numProjects);

    // State
    IERC20 public immutable cUSD;
    IProjectRegistry public immutable projectRegistry;

    // Funding round state
    bool public roundActive;
    uint256 public roundNumber;
    uint256 public matchingPool; // in CELO (native)

    // Per-project stats
    struct ProjectStats {
        uint256 totalContributions; // in cUSD
        uint256 numUniqueContributors;
        uint256 sumSqrtContributions; // sum of sqrt(contribution) per user, scaled
        mapping(address => uint256) contributions; // user => amount
        mapping(address => bool) hasContributed;
        address[] contributors;
    }

    // projectId => ProjectStats
    mapping(uint256 => ProjectStats) private _projectStats;
    // List of projectIds that received contributions this round
    uint256[] private _activeProjectIds;
    mapping(uint256 => bool) private _projectActiveThisRound;

    // Constants
    uint256 private constant SQRT_SCALE = 1e9;

    // Constructor
    constructor(address _projectRegistry, address _cUSD)
        Ownable(msg.sender)
     {
        require(_projectRegistry != address(0), "Invalid registry");
        require(_cUSD != address(0), "Invalid cUSD");
        projectRegistry = IProjectRegistry(_projectRegistry);
        cUSD = IERC20(_cUSD);
    }

    // Contribute cUSD to a project
    function contribute(uint256 _projectId, uint256 _amount) external {
        require(roundActive, "Funding round not active");
        require(_amount > 0, "Amount must be > 0");

        // Check project exists and is active
        (uint256 id, , , , , bool isActive) = projectRegistry.getProject(_projectId);
        require(id == _projectId && isActive, "Invalid or inactive project");

        // Transfer cUSD from user
        require(cUSD.transferFrom(msg.sender, address(this), _amount), "cUSD transfer failed");

        ProjectStats storage stats = _projectStats[_projectId];

        // Track unique contributors
        if (!stats.hasContributed[msg.sender]) {
            stats.hasContributed[msg.sender] = true;
            stats.numUniqueContributors += 1;
            stats.contributors.push(msg.sender);
        }

        // Update contributions
        stats.contributions[msg.sender] += _amount;
        stats.totalContributions += _amount;

        // Update sum of sqrt(contributions) for this user
        uint256 sqrtPrev = _sqrt(stats.contributions[msg.sender] - _amount);
        uint256 sqrtNew = _sqrt(stats.contributions[msg.sender]);
        // Remove previous sqrt, add new sqrt
        if (stats.sumSqrtContributions >= sqrtPrev) {
            stats.sumSqrtContributions = stats.sumSqrtContributions - sqrtPrev + sqrtNew;
        } else {
            stats.sumSqrtContributions = sqrtNew; // fallback, should not happen
        }

        // Track project as active this round
        if (!_projectActiveThisRound[_projectId]) {
            _activeProjectIds.push(_projectId);
            _projectActiveThisRound[_projectId] = true;
        }

        emit ContributionMade(msg.sender, _projectId, _amount);
    }

    // Owner deposits matching funds (in CELO native)
    function depositMatchingFunds() external payable onlyOwner {
        require(roundActive, "Round not active");
        require(msg.value > 0, "No CELO sent");
        matchingPool += msg.value;
    }

    // Start a new round
    function startRound() external onlyOwner {
        require(!roundActive, "Round already active");
        roundActive = true;
        roundNumber += 1;
        // Reset matching pool for new round
        matchingPool = 0;
    }

    // End the current round
    function endRound() external onlyOwner {
        require(roundActive, "No active round");
        roundActive = false;
    }

    // Distribute matching funds and direct contributions
    function distributeMatchingFunds() external onlyOwner {
        require(!roundActive, "Round still active");
        require(matchingPool > 0, "No matching funds");

        // Calculate total (sumSqrtContributions^2) for all projects
        uint256 totalQuadratic = 0;
        uint256 numProjects = _activeProjectIds.length;
        uint256[] memory projectQuadratics = new uint256[](numProjects);

        for (uint256 i = 0; i < numProjects; i++) {
            uint256 pid = _activeProjectIds[i];
            ProjectStats storage stats = _projectStats[pid];
            // Quadratic funding: (sum of sqrt(contributions))^2
            uint256 quad = (stats.sumSqrtContributions * stats.sumSqrtContributions) / SQRT_SCALE;
            projectQuadratics[i] = quad;
            totalQuadratic += quad;
        }

        // Distribute matching funds and direct cUSD to project owners
        for (uint256 i = 0; i < numProjects; i++) {
            uint256 pid = _activeProjectIds[i];
            ProjectStats storage stats = _projectStats[pid];

            // Get project owner
            (, address owner, , , , ) = projectRegistry.getProject(pid);
            require(owner != address(0), "Project owner not found");

            // Matching funds
            uint256 matchAmount = 0;
            if (totalQuadratic > 0) {
                matchAmount = (matchingPool * projectQuadratics[i]) / totalQuadratic;
            }
            if (matchAmount > 0) {
                (bool sent, ) = owner.call{value: matchAmount}("");
                require(sent, "CELO transfer failed");
            }

            // Direct cUSD contributions
            if (stats.totalContributions > 0) {
                require(cUSD.transfer(owner, stats.totalContributions), "cUSD transfer failed");
            }

            // Reset project stats for next round
            _resetProjectStats(pid);
        }

        // Reset round state
        delete _activeProjectIds;
        matchingPool = 0;

        emit MatchingFundsDistributed(matchingPool, numProjects);
    }

    // View functions
    function getProjectStats(uint256 _projectId) external view returns (
        uint256 totalContributions,
        uint256 numUniqueContributors,
        uint256 sumSqrtContributions
    ) {
        ProjectStats storage stats = _projectStats[_projectId];
        return (
            stats.totalContributions,
            stats.numUniqueContributors,
            stats.sumSqrtContributions
        );
    }

    function getContributorAmount(uint256 _projectId, address _user) external view returns (uint256) {
        return _projectStats[_projectId].contributions[_user];
    }

    function getActiveProjectIds() external view returns (uint256[] memory) {
        return _activeProjectIds;
    }

    // Internal: Reset project stats for next round
    function _resetProjectStats(uint256 _projectId) internal {
        ProjectStats storage stats = _projectStats[_projectId];
        for (uint256 i = 0; i < stats.contributors.length; i++) {
            address contributor = stats.contributors[i];
            stats.contributions[contributor] = 0;
            stats.hasContributed[contributor] = false;
        }
        delete stats.contributors;
        stats.totalContributions = 0;
        stats.numUniqueContributors = 0;
        stats.sumSqrtContributions = 0;
        _projectActiveThisRound[_projectId] = false;
    }

    // Internal: Babylonian method for sqrt, scaled by SQRT_SCALE
    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x * SQRT_SCALE + 1) / 2;
        uint256 y = x * SQRT_SCALE;
        while (z < y) {
            y = z;
            z = (x * SQRT_SCALE / z + z) / 2;
        }
        return y;
    }

    // Fallback to receive CELO
    receive() external payable {}
}
