const { ethers, network } = require("hardhat"); // Import network from hardhat

async function main() {
  console.log("Starting deployment...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Define cUSD token address based on network
  let cUSDTokenAddress;
  const isLocalNetwork = network.name === "hardhat" || network.name === "localhost";

  if (isLocalNetwork) {
    console.log("\nDetecting local network. Deploying Mock cUSD...");
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockCUSD = await MockERC20.deploy("Mock cUSD", "mCUSD");
    await mockCUSD.waitForDeployment();
    cUSDTokenAddress = await mockCUSD.getAddress();
    console.log("Mock cUSD deployed to:", cUSDTokenAddress);
    console.log(`Minted ${ethers.formatUnits(await mockCUSD.balanceOf(deployer.address), 18)} mCUSD to deployer.`);
  } else {
    // Celo Alfajores cUSD token address for testnet
    cUSDTokenAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
    console.log("\nDetecting Celo Alfajores. Using official cUSD token address:", cUSDTokenAddress);
  }

  try {
    // 1. Deploy AttestationService
    console.log("\n1. Deploying AttestationService...");
    const AttestationService = await ethers.getContractFactory("AttestationService");
    const attestationService = await AttestationService.deploy();
    await attestationService.waitForDeployment();
    console.log("AttestationService deployed to:", attestationService.target);

    // 2. Deploy ProjectRegistry with AttestationService address
    console.log("\n2. Deploying ProjectRegistry...");
    const ProjectRegistry = await ethers.getContractFactory("ProjectRegistry");
    const projectRegistry = await ProjectRegistry.deploy(attestationService.target);
    await projectRegistry.waitForDeployment();
    console.log("ProjectRegistry deployed to:", projectRegistry.target);

    // 3. Deploy QuadraticFunding with ProjectRegistry address and cUSD token address
    console.log("\n3. Deploying QuadraticFunding...");
    const QuadraticFunding = await ethers.getContractFactory("QuadraticFunding");
    const quadraticFunding = await QuadraticFunding.deploy(
      projectRegistry.target,
      cUSDTokenAddress // Use the dynamically determined cUSD address
    );
    await quadraticFunding.waitForDeployment();
    console.log("QuadraticFunding deployed to:", quadraticFunding.target);

    // Log all deployed addresses
    console.log("\n=== DEPLOYMENT SUMMARY ===");
    console.log("Network:", network.name);
    console.log("Deployer:", deployer.address);
    console.log("AttestationService:", attestationService.target);
    console.log("ProjectRegistry:", projectRegistry.target);
    console.log("QuadraticFunding:", quadraticFunding.target);
    console.log("cUSD Token (used for QuadraticFunding):", cUSDTokenAddress);
    console.log("========================\n");

    // Verification commands (adjusted for conditional cUSD)
    console.log("To verify contracts on CeloScan (if on Alfajores) or Etherscan (if on other networks), run:");
    console.log(`npx hardhat verify --network ${network.name} ${attestationService.target}`);
    console.log(`npx hardhat verify --network ${network.name} ${projectRegistry.target} ${attestationService.target}`);
    console.log(`npx hardhat verify --network ${network.name} ${quadraticFunding.target} ${projectRegistry.target} ${cUSDTokenAddress}`);

  } catch (error) {
    console.error("Deployment failed:", error);
    process.exit(1);
  }
}

// Handle errors
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  

  