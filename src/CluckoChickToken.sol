// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChickToken is ERC20, Ownable {
    constructor() ERC20("ChickToken", "CHICK") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    // Prevent all transfers by reverting in public transfer functions
    function transfer(address, uint256) public pure override returns (bool) {
        revert("ChickToken is non-transferable");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("ChickToken is non-transferable");
    }
}
