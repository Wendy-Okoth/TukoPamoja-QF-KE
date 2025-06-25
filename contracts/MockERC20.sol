// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Using 0.8.20, adjust if your other contracts use a slightly different patch version

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Added for _mint function restriction if needed

contract MockERC20 is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {
        // Mint a large amount of tokens to the deployer for testing purposes
        _mint(msg.sender, 1_000_000 * 10**18); // Mint 1,000,000 tokens
    }

    // Optional: Add a public mint function for testing if you need to get more tokens later
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}