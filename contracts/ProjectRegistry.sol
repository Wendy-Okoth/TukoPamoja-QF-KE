// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAttestationService {
    function hasAttestationType(address user, string calldata attestationType) external view returns (bool);
}

contract ProjectRegistry {
    struct Project {
        uint256 id;
        address owner;
        string name;
        string descriptionCID;
        string category;
        bool isActive;
        string[] imageCIDs; // New field for image CIDs/URLs
        string[] audioCIDs; // New field for audio CIDs/URLs
    }

    event ProjectSubmitted(
        uint256 indexed id,
        address indexed owner,
        string name,
        string descriptionCID,
        string category,
        string[] imageCIDs, // Updated event
        string[] audioCIDs  // Updated event
    );

    IAttestationService public attestationService;
    uint256 private _nextProjectId = 1;

    mapping(uint256 => Project) private _projects;
    uint256[] private _activeProjectIds;

    constructor(address attestationServiceAddress) {
        require(attestationServiceAddress != address(0), "Invalid attestation service address");
        attestationService = IAttestationService(attestationServiceAddress);
    }

    function submitProject(
        string calldata name,
        string calldata descriptionCID,
        string calldata category,
        string[] calldata imageCIDs, // New parameter
        string[] calldata audioCIDs  // New parameter
    ) external {
        require(
            attestationService.hasAttestationType(msg.sender, "Artist"),
            "Not authorized: must have 'Artist' attestation"
        );
        require(bytes(name).length > 0, "Project name required");
        require(bytes(descriptionCID).length > 0, "Description CID required");
        require(bytes(category).length > 0, "Category required");

        uint256 projectId = _nextProjectId++;
        Project memory newProject = Project({
            id: projectId,
            owner: msg.sender,
            name: name,
            descriptionCID: descriptionCID,
            category: category,
            isActive: true,
            imageCIDs: imageCIDs, // Assign new fields
            audioCIDs: audioCIDs  // Assign new fields
        });

        _projects[projectId] = newProject;
        _activeProjectIds.push(projectId);

        emit ProjectSubmitted(projectId, msg.sender, name, descriptionCID, category, imageCIDs, audioCIDs); // Emit new fields
    }

    function getProject(uint256 projectId) external view returns (
        uint256 id,
        address owner,
        string memory name,
        string memory descriptionCID,
        string memory category,
        bool isActive,
        string[] memory imageCIDs, // New return value
        string[] memory audioCIDs  // New return value
    ) {
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");
        return (
            project.id,
            project.owner,
            project.name,
            project.descriptionCID,
            project.category,
            project.isActive,
            project.imageCIDs, // Return new fields
            project.audioCIDs  // Return new fields
        );
    }

    // This function will now return Project structs with the new fields
    function getAllActiveProjects() external view returns (Project[] memory) {
        uint256 count = _activeProjectIds.length;
        Project[] memory activeProjects = new Project[](count);
        for (uint256 i = 0; i < count; i++) {
            activeProjects[i] = _projects[_activeProjectIds[i]];
        }
        return activeProjects;
    }
}
