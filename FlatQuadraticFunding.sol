PRIVATE_KEY loaded: true
CELOSCAN_API_KEY loaded: true
// Sources flattened with hardhat v2.24.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File contracts/QuadraticFunding.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;
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
