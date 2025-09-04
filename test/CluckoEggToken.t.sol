// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { EggsToken } from "../src/CluckoEggToken.sol";

contract CluckoEggTokenTest is Test {
    EggsToken public eggsToken;

    function setUp() public {
        eggsToken = new EggsToken();
    }

    function testInitialSupply() public view {
        assertEq(eggsToken.totalSupply(), 0);
    }

    function testMinting() public {
        uint256 initialSupply = eggsToken.totalSupply();
        eggsToken.mint(address(this), 100);
        uint256 newSupply = eggsToken.totalSupply();
        assertEq(newSupply, initialSupply + 100);
    }

    function testMintingForNonOwner() public {
        address nonOwner = address(0x123);
        vm.prank(nonOwner);
        vm.expectRevert(); 
        eggsToken.mint(nonOwner, 50);
    }

    function testBalanceAfterMinting() public {
        eggsToken.mint(address(this), 200);
        uint256 balance = eggsToken.balanceOf(address(this));
        assertEq(balance, 200);
    }

    function testTransfer() public {
        eggsToken.mint(address(this), 300);
        address recipient = address(0x456);
        eggsToken.transfer(recipient, 100);
        uint256 senderBalance = eggsToken.balanceOf(address(this));
        uint256 recipientBalance = eggsToken.balanceOf(recipient);
        assertEq(senderBalance, 200);
        assertEq(recipientBalance, 100);
    }
}