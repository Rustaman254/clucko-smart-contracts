// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EggsToken is ERC20, Ownable {
    constructor() ERC20("EggsToken", "EGG") Ownable(msg.sender){}

    // Only owner (project owner) can mint Eggs representing budget
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
