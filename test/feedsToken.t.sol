// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/FeedsToken.sol";

contract FeedsTokenTest is Test {
    FeedsToken feeds;
    address alice = address(0x1);

    function setUp() public {
        feeds = new FeedsToken();
        feeds.mint(alice, 1000 ether);
    }

    function testMintAndBurnFrom() public {
        assertEq(feeds.balanceOf(alice), 1000 ether);

        vm.prank(address(this)); 
        feeds.burnFrom(alice, 300 ether);

        assertEq(feeds.balanceOf(alice), 700 ether);
    }
}
