// scripts/deployMockERC20.js
const { ethers } = require("hardhat");

async function main() {
  // Get the ContractFactory for MockERC20
  const MockERC20 = await ethers.getContractFactory("MockERC20");

  // --- THIS IS THE CHANGE YOU NEED TO MAKE ---
  // Define the constructor arguments for your MockERC20
  const tokenName = "Tuko Pamoja Mock Token"; // A descriptive name for your token
  const tokenSymbol = "TPMT";             // A symbol for your token

  // Deploy the contract, passing the name and symbol
  const mockERC20 = await MockERC20.deploy(tokenName, tokenSymbol);
  // ------------------------------------------

  // Wait for the deployment to be confirmed on the blockchain
  await mockERC20.waitForDeployment();

  // Log the deployed address
  console.log(`MockERC20 deployed to: ${await mockERC20.getAddress()}`);
  console.log(`Token Name: ${tokenName}`);
  console.log(`Token Symbol: ${tokenSymbol}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});