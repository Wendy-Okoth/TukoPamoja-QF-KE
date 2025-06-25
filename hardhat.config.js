require("dotenv").config(); // must be at the top
require("@nomicfoundation/hardhat-toolbox");

const PRIVATE_KEY = process.env.PRIVATE_KEY;

if (!PRIVATE_KEY) {
  console.error("PRIVATE_KEY is not set in the .env file. Please check your .env file.");
  process.exit(1);
}

if (!process.env.CELOSCAN_API_KEY) {
  console.error("CELOSCAN_API_KEY is not set in the .env file. Please check your .env file.");
  process.exit(1);
}

console.log("PRIVATE_KEY loaded:", !!PRIVATE_KEY);
console.log("CELOSCAN_API_KEY loaded:", !!process.env.CELOSCAN_API_KEY);

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: [PRIVATE_KEY],
      chainId: 44787,
    },
  },
  etherscan: {
    apiKey: {
      alfajores: process.env.CELOSCAN_API_KEY,
    },
    customChains: [
      {
        network: "alfajores",
        chainId: 44787,
        urls: {
          apiURL: "https://api-alfajores.celoscan.io/api",
          browserURL: "https://alfajores.celoscan.io",
        },
      },
    ],
  },
  sourcify: {
    enabled: false,
  },
};
