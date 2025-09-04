// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/CluckoChickToken.sol";

contract ChickTokenTest is Test {
    ChickToken chicks;
    address alice = address(0x1);

    function setUp() public {
        chicks = new ChickToken();
        // Owner mint
        vm.prank(address(this));
        chicks.mint(alice, 5 ether);
    }

    function testMintBurnNonTransferable() public {
        assertEq(chicks.balanceOf(alice), 5 ether);

        vm.prank(address(this));
        chicks.burn(alice, 2 ether);
        assertEq(chicks.balanceOf(alice), 3 ether);

        vm.prank(alice);
        vm.expectRevert("ChickToken is non-transferable");
        chicks.transfer(address(0x2), 1);
    }
}
