// C:\Users\user\Documents\Projects\TukoPamoja\scripts\fundAccount.js
const { ethers } = require("hardhat");

async function main() {
    // Get the deployer account from Hardhat, which typically holds a lot of test ETH/CELO
    const [deployer] = await ethers.getSigners();

    // !!! IMPORTANT: THIS IS YOUR METAMASK ACCOUNT ADDRESS (already correctly updated by you) !!!
    // This is the address connected to your frontend DApp.
    const recipientAddress = "0xD0486A66Ffaa4694237d8935434a7A636702710d";

    // !!! IMPORTANT: THIS IS YOUR DEPLOYED MOCK CUSD CONTRACT ADDRESS (updated) !!!
    const mockCUSDAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

    // Get the Mock cUSD contract instance
    const MockCUSD = await ethers.getContractFactory("MockERC20"); // Assuming your mock cUSD is named MockERC20
    const mockCUSD = await MockCUSD.attach(mockCUSDAddress);

    // Amount to mint (e.g., 1000 cUSD, converted to 18 decimal places for the contract)
    const amountToMint = ethers.parseUnits("1000", 18);

    console.log(`Attempting to mint ${ethers.formatUnits(amountToMint, 18)} mCUSD to ${recipientAddress}...`);
    
    // Call the mint function on the Mock cUSD contract
    // This assumes your MockERC20 contract has a 'mint' function that deployer can call.
    const tx = await mockCUSD.mint(recipientAddress, amountToMint);
    await tx.wait(); // Wait for the transaction to be mined
    console.log(`Successfully minted mCUSD! Transaction Hash: ${tx.hash}`);

    // Verify the balance
    const balance = await mockCUSD.balanceOf(recipientAddress);
    console.log(`Current balance of ${recipientAddress}: ${ethers.formatUnits(balance, 18)} mCUSD`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});