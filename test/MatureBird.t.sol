// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/MatureBird.sol";

contract MatureBirdNFTTest is Test {
    MatureBirdNFT nft;
    address alice = address(0x1);

    function setUp() public {
        nft = new MatureBirdNFT();
    }

    function testMintAndOwnerOf() public {
        vm.prank(address(this));
        uint256 tokenId = nft.mint(alice, "ipfs://metadata/1");

        assertEq(nft.ownerOf(tokenId), alice);
        assertEq(keccak256(bytes(nft.tokenURI(tokenId))), keccak256(bytes("ipfs://metadata/1")));
    }

    function testBurn() public {
        vm.prank(address(this));
        uint256 tokenId = nft.mint(alice, "ipfs://metadata/1");

        vm.prank(address(this));
        nft.burn(tokenId);

        vm.expectRevert();
        nft.ownerOf(tokenId);
    }
}
