// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/BirdLifecycleAndProjectManager.sol";
import "../src/CluckoEggToken.sol";
import "../src/FeedsToken.sol";
import "../src/CluckoChickToken.sol";
import "../src/MatureBird.sol";

contract BirdLifecycleAndProjectManagerTest is Test {
    EggsToken eggs;
    FeedsToken feeds;
    ChickToken chicks;
    MatureBirdNFT nft;
    BirdLifecycleAndProjectManager manager;

    address alice = address(0x1);

    function setUp() public {
        // Deploy token contracts
        eggs = new EggsToken();
        feeds = new FeedsToken();
        chicks = new ChickToken();
        nft = new MatureBirdNFT();

        // Log and assert ownership
        console.log("Test contract address:", address(this));
        console.log("EggsToken owner:", eggs.owner());
        console.log("FeedsToken owner:", feeds.owner());
        console.log("ChickToken owner:", chicks.owner());
        console.log("MatureBirdNFT owner:", nft.owner());

        assertEq(eggs.owner(), address(this), "Test contract should own EggsToken");
        assertEq(feeds.owner(), address(this), "Test contract should own FeedsToken");
        assertEq(chicks.owner(), address(this), "Test contract should own ChickToken");
        assertEq(nft.owner(), address(this), "Test contract should own MatureBirdNFT");

        // Deploy manager contract
        manager = new BirdLifecycleAndProjectManager(
            address(chicks),
            address(nft),
            address(feeds),
            address(eggs)
        );

        // Log manager address
        console.log("Manager contract address:", address(manager));

        // Transfer ownership with try-catch to identify failing contract
        try eggs.transferOwnership(address(manager)) {
            console.log("EggsToken ownership transferred successfully");
        } catch Error(string memory reason) {
            console.log("EggsToken transferOwnership failed:", reason);
            revert("EggsToken ownership transfer failed");
        }

        try feeds.transferOwnership(address(manager)) {
            console.log("FeedsToken ownership transferred successfully");
        } catch Error(string memory reason) {
            console.log("FeedsToken transferOwnership failed:", reason);
            revert("FeedsToken ownership transfer failed");
        }

        try chicks.transferOwnership(address(manager)) {
            console.log("ChickToken ownership transferred successfully");
        } catch Error(string memory reason) {
            console.log("ChickToken transferOwnership failed:", reason);
            revert("ChickToken ownership transfer failed");
        }

        try nft.transferOwnership(address(manager)) {
            console.log("MatureBirdNFT ownership transferred successfully");
        } catch Error(string memory reason) {
            console.log("MatureBirdNFT transferOwnership failed:", reason);
            revert("MatureBirdNFT ownership transfer failed");
        }

        // Handle Ownable2Step if applicable
        // Uncomment if your token contracts use Ownable2Step
        /*
        vm.prank(address(manager));
        try eggs.acceptOwnership() {
            console.log("EggsToken ownership accepted");
        } catch Error(string memory reason) {
            console.log("EggsToken acceptOwnership failed:", reason);
        }

        vm.prank(address(manager));
        try feeds.acceptOwnership() {
            console.log("FeedsToken ownership accepted");
        } catch Error(string memory reason) {
            console.log("FeedsToken acceptOwnership failed:", reason);
        }

        vm.prank(address(manager));
        try chicks.acceptOwnership() {
            console.log("ChickToken ownership accepted");
        } catch Error(string memory reason) {
            console.log("ChickToken acceptOwnership failed:", reason);
        }

        vm.prank(address(manager));
        try nft.acceptOwnership() {
            console.log("MatureBirdNFT ownership accepted");
        } catch Error(string memory reason) {
            console.log("MatureBirdNFT acceptOwnership failed:", reason);
        }
        */

        // Verify ownership transfer
        assertEq(eggs.owner(), address(manager), "EggsToken ownership not transferred");
        assertEq(feeds.owner(), address(manager), "FeedsToken ownership not transferred");
        assertEq(chicks.owner(), address(manager), "ChickToken ownership not transferred");
        assertEq(nft.owner(), address(manager), "MatureBirdNFT ownership not transferred");

        // Mint tokens and set approvals
        vm.prank(address(manager));
        eggs.mint(alice, 1000 ether);
        vm.prank(address(manager));
        feeds.mint(alice, 1000 ether);

        vm.prank(alice);
        eggs.approve(address(manager), type(uint256).max);

        vm.prank(alice);
        feeds.approve(address(manager), type(uint256).max);
    }

    function testCreateProject() public {
        vm.prank(alice);
        manager.createProject();

        (address ownerOfProject, , bool exists) = manager.projects(1);
        assertTrue(exists);
        assertEq(ownerOfProject, alice);
    }

    function testPurchaseBasket() public {
        vm.prank(alice);
        manager.createProject();

        vm.prank(alice);
        manager.purchaseBasket(1, 200 ether);

        uint256 available = manager.totalAvailableEggs(1);
        assertEq(available, 200 ether);
    }

    function testAssignEggs() public {
        vm.prank(alice);
        manager.createProject();

        vm.prank(alice);
        manager.purchaseBasket(1, 200 ether);

        vm.prank(alice);
        manager.assignEggsToTask(1, 150 ether);

        uint256 left = manager.totalAvailableEggs(1);
        assertEq(left, 50 ether);
    }

    function testHatchFeedAndMatureLifecycle() public {
        vm.prank(address(manager));
        manager.hatchEgg(alice, "peacock", "ipfs://metadata/peacock", 1);

        uint256 chicksCount = manager.getChicksCount(alice);
        assertEq(chicksCount, 1);

        // Warp time past incubation
        vm.warp(block.timestamp + 4 days);

        // Feed 5 times
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(address(manager));
            feeds.mint(alice, 10 ether);
            vm.prank(alice);
            feeds.approve(address(manager), 10 ether);
            vm.prank(alice);
            manager.feedChick(0);
        }

        vm.prank(alice);
        manager.matureChick(0);

        (, , , , , bool exists) = manager.getChickInfo(alice, 0);
        assertFalse(exists);

        // Check NFT ownership for tokenId 1
        assertEq(nft.ownerOf(1), alice);
    }
}