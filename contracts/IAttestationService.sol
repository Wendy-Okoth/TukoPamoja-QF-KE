// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Ensure this matches or is compatible with your other contracts

interface IAttestationService {
    /**
     * @dev Checks if a user has a specific attestation type.
     * @param user The address of the user to check.
     * @param attestationType The string identifier for the attestation type (e.g., "Artist", "CommunityMember").
     * @return A boolean indicating whether the user has the attestation.
     */
    function hasAttestationType(address user, string calldata attestationType) external view returns (bool);

    /**
     * @dev Attests a user with a specific attestation type.
     * This function should typically be restricted to certain roles (e.g., owner, designated attestors).
     * @param user The address of the user to attest.
     * @param attestationType The string identifier for the attestation type.
     */
    function attest(address user, string calldata attestationType) external;

    /**
     * @dev Revokes a specific attestation type from a user.
     * This function should typically be restricted to certain roles.
     * @param user The address of the user from whom to revoke the attestation.
     * @param attestationType The string identifier for the attestation type to revoke.
     */
    function revokeAttestation(address user, string calldata attestationType) external;
}