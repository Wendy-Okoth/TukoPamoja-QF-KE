// scripts/grantAttestation.js
const { ethers } = require("hardhat");

async function main() {
    // IMPORTANT: Get the address of the account you connected in MetaMask
    const yourMetaMaskAddress = "0xD0486A66Ffaa4694237d8935434a7A636702710d"; // Your connected MetaMask address
    const attestationServiceAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; // Your deployed AttestationService address

    // Attach to the deployed contract
    const AttestationService = await ethers.getContractFactory("AttestationService");
    const attestationService = await AttestationService.attach(attestationServiceAddress);

    // Get the deployer account (which is the owner of AttestationService)
    const [deployer] = await ethers.getSigners();

    console.log("Using deployer account:", deployer.address);
    console.log("Connected MetaMask address:", yourMetaMaskAddress);

    // --- Step 1A: Make the deployer (owner) an attestor if not already ---
    console.log("Attempting to add deployer as an attestor (as owner)...");
    try {
        // The owner (deployer) adds itself as an attestor
        const addDeployerAttestorTx = await attestationService.connect(deployer).addAttestor(deployer.address);
        await addDeployerAttestorTx.wait();
        console.log("Successfully added deployer as an attestor!");
    } catch (error) {
        if (error.message.includes("Already an attestor")) {
            console.log("Deployer is already an attestor. Skipping 'addAttestor' for deployer.");
        } else {
            console.error("Error adding deployer as attestor:", error);
            // If this critical step fails, we cannot proceed
            process.exit(1);
        }
    }

    // --- Step 1B: Add your MetaMask address as an attestor (onlyOwner function) ---
    // This step is only necessary if your MetaMask address is different from the deployer's address
    if (deployer.address.toLowerCase() !== yourMetaMaskAddress.toLowerCase()) {
        console.log("Attempting to add MetaMask address as an attestor...");
        try {
            const addMetaMaskAttestorTx = await attestationService.connect(deployer).addAttestor(yourMetaMaskAddress);
            await addMetaMaskAttestorTx.wait();
            console.log("Successfully added MetaMask address as an attestor!");
        } catch (error) {
            if (error.message.includes("Already an attestor")) {
                console.log("MetaMask address is already an attestor. Skipping 'addAttestor' for MetaMask address.");
            } else {
                console.error("Error adding MetaMask address as attestor:", error);
                process.exit(1);
            }
        }
    } else {
        console.log("MetaMask address is the same as the deployer. No need to add it separately.");
    }

    // --- Step 2: Issue the 'Artist' attestation to your MetaMask address (onlyAttestor function) ---
    console.log("Attempting to issue 'Artist' attestation to MetaMask address...");
    try {
        // You need to provide a bytes32 hash for 'attestationHash'.
        // For testing, we can just use a keccak256 hash of some unique data.
        const attestationHash = ethers.keccak256(ethers.toUtf8Bytes("ArtistAttestationForProjectSubmission"));

        // Call the issueAttestation function using the deployer as the attestor
        // Since deployer is now an attestor, this call should succeed.
        const issueAttestationTx = await attestationService.connect(deployer).issueAttestation(
            yourMetaMaskAddress, // recipient
            "Artist",            // attestationType
            attestationHash      // attestationHash
        );
        await issueAttestationTx.wait();

        console.log("Transaction successful! 'Artist' attestation issued to", yourMetaMaskAddress);
        console.log("Transaction hash:", issueAttestationTx.hash);

        // --- Optional: Verify the attestation using the correct function name ---
        const hasArtistAttestation = await attestationService.hasAttestationType(yourMetaMaskAddress, "Artist");
        console.log("Does " + yourMetaMaskAddress + " have 'Artist' attestation? " + hasArtistAttestation);

    } catch (error) {
        console.error("Error issuing attestation:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });