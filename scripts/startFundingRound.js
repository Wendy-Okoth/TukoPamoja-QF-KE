// C:\Users\user\Documents\Projects\TukoPamoja\scripts\startFundingRound.js
const { ethers } = require("hardhat");

async function main() {
    // Get the deployer account from Hardhat (this account must be the owner of QuadraticFunding)
    const [deployer] = await ethers.getSigners();

    // !!! IMPORTANT: THIS IS YOUR DEPLOYED QUADRATIC FUNDING CONTRACT ADDRESS (updated) !!!
    const qfAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

    // Get the QuadraticFunding contract instance
    const QuadraticFunding = await ethers.getContractFactory("QuadraticFunding");
    const quadraticFunding = await QuadraticFunding.attach(qfAddress);

    // Check if the round is already active
    const roundActive = await quadraticFunding.roundActive();

    if (!roundActive) {
        console.log("Funding round is currently INACTIVE. Attempting to START round...");
        // Call the startRound function from the deployer (owner) account
        const tx = await quadraticFunding.connect(deployer).startRound();
        console.log(`Transaction sent to start round: ${tx.hash}`);
        await tx.wait(); // Wait for the transaction to be mined
        console.log("Funding round STARTED successfully!");
    } else {
        console.log("Funding round is ALREADY ACTIVE. No action needed.");
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});