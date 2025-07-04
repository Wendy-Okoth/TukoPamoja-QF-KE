// C:\Users\user\Documents\Projects\TukoPamoja\scripts\startFundingRound.js
const { ethers } = require("hardhat");

async function main() {
    console.log("Starting funding round...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log("Using account:", deployer.address);

    // IMPORTANT: These are the addresses from your LAST LOCAL DEPLOYMENT
    const QUADRATIC_FUNDING_ADDRESS = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

    try {
        // Get the QuadraticFunding contract instance
        const quadraticFunding = await ethers.getContractAt("QuadraticFunding", QUADRATIC_FUNDING_ADDRESS, deployer);
        
        console.log("QuadraticFunding contract address:", QUADRATIC_FUNDING_ADDRESS);
        
        // Check if round is already active
        const isRoundActive = await quadraticFunding.roundActive();
        console.log("Current round active status:", isRoundActive);
        
        if (isRoundActive) {
            console.log("Funding round is already active!");
            return;
        }
        
        // Start the funding round
        console.log("Starting new funding round...");
        const tx = await quadraticFunding.startRound();
        await tx.wait();
        
        console.log("✅ Funding round started successfully!");
        console.log("Transaction hash:", tx.hash);
        
        // Verify the round is now active
        const newRoundActive = await quadraticFunding.roundActive();
        const roundNumber = await quadraticFunding.roundNumber();
        console.log("New round active status:", newRoundActive);
        console.log("Round number:", roundNumber.toString());
        
    } catch (error) {
        console.error("Error starting funding round:", error);
        process.exit(1);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });