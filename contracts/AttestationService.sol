// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AttestationService is Ownable {
    // Events
    event AttestorAdded(address indexed attestor);
    event AttestorRemoved(address indexed attestor);
    event AttestationIssued(
        address indexed attestor,
        address indexed recipient,
        string attestationType,
        bytes32 attestationHash
    );

    // Attestor management
    mapping(address => bool) public isAttestor;

    // Attestation tracking: user => attestationTypeHash => bool
    mapping(address => mapping(bytes32 => bool)) private _hasAttestationType;

    // Modifier to restrict to attestors
    modifier onlyAttestor() {
        require(isAttestor[msg.sender], "Not an attestor");
        _;
    }

    // Add this constructor
    constructor() Ownable(msg.sender) {} 

    // Add an attestor (only owner)
    function addAttestor(address attestor) external onlyOwner {
        require(attestor != address(0), "Invalid attestor address");
        require(!isAttestor[attestor], "Already an attestor");
        isAttestor[attestor] = true;
        emit AttestorAdded(attestor);
    }

    // Remove an attestor (only owner)
    function removeAttestor(address attestor) external onlyOwner {
        require(isAttestor[attestor], "Not an attestor");
        isAttestor[attestor] = false;
        emit AttestorRemoved(attestor);
    }

    // Issue an attestation (only attestor)
    function issueAttestation(
        address recipient,
        string calldata attestationType,
        bytes32 attestationHash
    ) external onlyAttestor {
        require(recipient != address(0), "Invalid recipient");
        require(bytes(attestationType).length > 0, "Empty attestationType");
        require(attestationHash != bytes32(0), "Invalid attestationHash");

        bytes32 typeHash = keccak256(abi.encodePacked(attestationType));
        require(!_hasAttestationType[recipient][typeHash], "Attestation already exists");

        _hasAttestationType[recipient][typeHash] = true;

        emit AttestationIssued(msg.sender, recipient, attestationType, attestationHash);
    }

    // Check if a user has a specific attestation type
    function hasAttestationType(address user, string calldata attestationType) external view returns (bool) {
        bytes32 typeHash = keccak256(abi.encodePacked(attestationType));
        return _hasAttestationType[user][typeHash];
    }
}
