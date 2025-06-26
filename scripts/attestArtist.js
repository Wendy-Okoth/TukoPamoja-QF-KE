// C:\Users\user\Documents\Projects\TukoPamoja\scripts\attestArtist.js
const { ethers } = require("hardhat");

async function main() {
    // This is the account that deployed the AttestationService and is its owner.
    // It will be used to add itself as an attestor, and then issue the attestation.
    const [deployer] = await ethers.getSigners();

    // !!! IMPORTANT: THIS IS YOUR METAMASK ACCOUNT ADDRESS (already correctly updated by you) !!!
    const recipientAddress = "0xD0486A66Ffaa4694237d8935434a7A636702710d"; // Your MetaMask address

    // !!! IMPORTANT: THIS IS YOUR ATTESTATION SERVICE CONTRACT ADDRESS (updated) !!!
    const attestationServiceAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; // Your AttestationService address

    const AttestationService = await ethers.getContractFactory("AttestationService");
    const attestationService = await AttestationService.attach(attestationServiceAddress);

    const attestationType = "Artist"; // The specific attestation type
    const attestationHash = ethers.keccak256(ethers.toUtf8Bytes("placeholder_hash_for_artist_attestation")); // A dummy hash for now

    console.log(`--- Attestation Process Started ---`);
    console.log(`Recipient: ${recipientAddress}`);
    console.log(`Attestation Type: '${attestationType}'`);
    console.log(`AttestationService Address: ${attestationServiceAddress}`);
    console.log(`Deployer (Owner) Address: ${deployer.address}`);

    // Step 1: Make the deployer an attestor (if not already)
    const isDeployerAttestor = await attestationService.isAttestor(deployer.address);
    if (!isDeployerAttestor) {
        console.log(`Deployer (${deployer.address}) is not yet an attestor. Adding now...`);
        const addAttestorTx = await attestationService.connect(deployer).addAttestor(deployer.address);
        await addAttestorTx.wait();
        console.log(`Deployer successfully added as an attestor! Tx: ${addAttestorTx.hash}`);
    } else {
        console.log(`Deployer (${deployer.address}) is already an attestor.`);
    }

    // Step 2: Check if recipient already has the attestation
    const hasExistingAttestation = await attestationService.hasAttestationType(recipientAddress, attestationType);
    if (hasExistingAttestation) {
        console.log(`${recipientAddress} already has the '${attestationType}' attestation. Skipping issueAttestation.`);
        return; // Exit if already attested
    }

    // Step 3: Issue the attestation (now that deployer is an attestor)
    console.log(`Issuing '${attestationType}' attestation to ${recipientAddress}...`);
    const issueAttestationTx = await attestationService.connect(deployer).issueAttestation(
        recipientAddress,
        attestationType,
        attestationHash
    );
    await issueAttestationTx.wait();
    console.log(`Successfully issued '${attestationType}' attestation to ${recipientAddress}! Tx: ${issueAttestationTx.hash}`);

    // Final verification
    const newIsAttested = await attestationService.hasAttestationType(recipientAddress, attestationType);
    console.log(`Verification: ${recipientAddress} has '${attestationType}' attestation: ${newIsAttested}`);
    console.log(`--- Attestation Process Complete ---`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});