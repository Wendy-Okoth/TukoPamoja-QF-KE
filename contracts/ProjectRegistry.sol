// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAttestationService.sol";

// Defines a struct for storing project details
struct Project {
    uint256 id;
    address payable owner; // Made payable for potential future uses (e.g. direct payments)
    string name;
    string descriptionCID; // IPFS hash for detailed description
    string category;
    string[] imageCIDs;   // Array of IPFS hashes for images
    string[] audioCIDs;   // Array of IPFS hashes for audio files
    bool isActive;        // Projects can be deactivated (e.g., if fraudulent)
    uint256 timestamp;    // When the project was submitted (using timestamp as per your code)
}

// NEW: Struct to define a single project update
struct ProjectUpdate {
    uint256 timestamp;
    string message;     // The text content of the update
    string[] mediaCIDs; // Optional: CIDs for images/audio related to the update
}


contract ProjectRegistry is Ownable {
    uint256 public nextProjectId; // Starts from 0, increments
    mapping(uint256 => Project) public projects; // Stores projects by ID
    mapping(address => uint256[]) public ownerProjects; // Track projects by owner (optional, but good for profile)

    // NEW: Mapping to store arrays of updates for each project ID
    mapping(uint256 => ProjectUpdate[]) public projectUpdates;

    IAttestationService public attestationService; // Instance of the attestation service

    // Event for project submission
    event ProjectSubmitted(
        uint256 indexed projectId,
        address indexed owner,
        string name,
        string category,
        string descriptionCID,
        string[] imageCIDs,
        string[] audioCIDs,
        uint256 timestamp
    );

    // NEW: Event for when a project update is posted
    event ProjectUpdatePosted(
        uint256 indexed projectId,
        address indexed updater,
        uint256 timestamp,
        string message // Emitting full message for easier frontend display
    );

    // Constructor to set the owner and AttestationService address
    constructor(address _attestationServiceAddress) Ownable(msg.sender) {
        require(_attestationServiceAddress != address(0), "AttestationService address cannot be zero");
        attestationService = IAttestationService(_attestationServiceAddress);
        nextProjectId = 0; // Initialize next project ID
    }

    /**
     * @dev Throws if the caller is not the owner of the project.
     * @param _projectId The ID of the project to check.
     */
    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == msg.sender, "Not authorized: only project owner can perform this action");
        _;
    }

    /**
     * @dev Allows users with 'Artist' attestation to submit a new project.
     * @param _name The name of the project.
     * @param _descriptionCID The IPFS Content Identifier (CID) for the project's detailed description.
     * @param _category The category of the project (e.g., "Art", "Environment").
     * @param _imageCIDs An array of IPFS CIDs for project images.
     * @param _audioCIDs An array of IPFS CIDs for project audio files.
     */
    function submitProject(
        string memory _name,
        string memory _descriptionCID,
        string memory _category,
        string[] memory _imageCIDs,
        string[] memory _audioCIDs
    ) public {
        // Ensure the sender has the 'Artist' attestation
        require(attestationService.hasAttestationType(msg.sender, "Artist"), "Not authorized: must have 'Artist' attestation");
        require(bytes(_name).length > 0, "Project name cannot be empty");
        require(bytes(_descriptionCID).length > 0, "Description CID cannot be empty");
        require(bytes(_category).length > 0, "Category cannot be empty");

        uint256 projectId = nextProjectId; // Get current ID
        nextProjectId++;                   // Increment for next project

        projects[projectId] = Project({
            id: projectId,
            owner: payable(msg.sender),
            name: _name,
            descriptionCID: _descriptionCID,
            category: _category,
            imageCIDs: _imageCIDs,
            audioCIDs: _audioCIDs,
            isActive: true, // Projects are active by default upon submission
            timestamp: block.timestamp
        });

        ownerProjects[msg.sender].push(projectId); // Track project by owner

        emit ProjectSubmitted(projectId, msg.sender, _name, _category, _descriptionCID, _imageCIDs, _audioCIDs, block.timestamp);
    }

    /**
     * @dev Retrieves details of a specific project.
     * @param _projectId The ID of the project.
     * @return id The project's unique ID.
     * @return owner The address of the project owner.
     * @return name The name of the project.
     * @return descriptionCID The IPFS CID for the project's description.
     * @return category The project's category.
     * @return imageCIDs An array of IPFS CIDs for project images.
     * @return audioCIDs An array of IPFS CIDs for project audio files.
     * @return isActive The active status of the project.
     * @return timestamp The timestamp when the project was submitted.
     */
    function getProject(uint256 _projectId) public view returns (
        uint256 id,
        address owner,
        string memory name,
        string memory descriptionCID,
        string memory category,
        string[] memory imageCIDs,
        string[] memory audioCIDs,
        bool isActive,
        uint256 timestamp
    ) {
        Project storage project = projects[_projectId];
        // Check if project.id matches _projectId to confirm existence (default struct values are 0)
        require(project.id == _projectId, "Project does not exist");

        return (
            project.id,
            project.owner,
            project.name,
            project.descriptionCID,
            project.category,
            project.imageCIDs,
            project.audioCIDs,
            project.isActive,
            project.timestamp
        );
    }

    /**
     * @dev Returns all currently active projects.
     * Iterates through all possible project IDs up to `nextProjectId`.
     * This is a simple implementation and might be gas-intensive for very many projects.
     */
    function getAllActiveProjects() public view returns (Project[] memory) {
        // Filter out non-existent projects or inactive ones
        uint256 activeCount = 0;
        for(uint256 i = 0; i < nextProjectId; i++) {
            if(projects[i].id == i && projects[i].isActive) {
                activeCount++;
            }
        }

        Project[] memory activeProjects = new Project[](activeCount);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < nextProjectId; i++) {
            if (projects[i].id == i && projects[i].isActive) {
                activeProjects[currentIdx] = projects[i];
                currentIdx++;
            }
        }
        return activeProjects;
    }


    /**
     * @dev Allows the project owner to deactivate their project.
     * Can be used if a project needs to be taken down (e.g., fraudulent activity).
     * @param _projectId The ID of the project to deactivate.
     */
    function deactivateProject(uint256 _projectId) public onlyProjectOwner(_projectId) {
        require(projects[_projectId].isActive, "Project is already inactive");
        projects[_projectId].isActive = false;
        // Optionally emit an event for project deactivation
    }

    /**
     * @dev Allows the project owner to post an update for their project.
     * @param _projectId The ID of the project to update.
     * @param _message The text content of the update.
     * @param _mediaCIDs Optional array of IPFS CIDs for media related to the update.
     */
    function postProjectUpdate(uint256 _projectId, string memory _message, string[] memory _mediaCIDs)
        public
        onlyProjectOwner(_projectId) // Only the project owner can post updates
    {
        require(bytes(_message).length > 0, "Update message cannot be empty");
        require(projects[_projectId].id == _projectId, "Project does not exist"); // Ensure project exists

        projectUpdates[_projectId].push(ProjectUpdate({
            timestamp: block.timestamp,
            message: _message,
            mediaCIDs: _mediaCIDs
        }));

        // Emit an event for frontend to listen to
        emit ProjectUpdatePosted(_projectId, msg.sender, block.timestamp, _message);
    }

    /**
     * @dev Retrieves all updates for a given project.
     * @param _projectId The ID of the project.
     * @return An array of ProjectUpdate structs.
     */
    function getProjectUpdates(uint256 _projectId) public view returns (ProjectUpdate[] memory) {
        require(projects[_projectId].id == _projectId, "Project does not exist"); // Ensure project exists
        return projectUpdates[_projectId];
    }
}

