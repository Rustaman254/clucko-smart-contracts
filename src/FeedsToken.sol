// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeedsToken is ERC20, Ownable {
    constructor() ERC20("FeedsToken", "FEED") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("Transfers are disabled");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Transfers are disabled");
    }
}
