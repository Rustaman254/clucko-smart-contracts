// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import "../src/CluckoProjectManagement.sol";
import { EggsToken } from "../src/CluckoEggToken.sol";

contract CluckoProjectManagementTest is Test {
    EggsToken public eggsToken;
    CluckoProjectManagement public projectManagement;

    address public contractOwner = address(0xABCD);
    address public projectOwner = address(0x1234);
    address public unauthorized = address(0x9999);

    bytes32 public projectId;

    function setUp() public {
        vm.startPrank(contractOwner);
        eggsToken = new EggsToken();
        projectManagement = new CluckoProjectManagement(eggsToken);
        vm.stopPrank();

        projectId = keccak256(abi.encodePacked("Test Project"));

        vm.prank(contractOwner);
        projectManagement.createProject(projectId, projectOwner);

        vm.startPrank(contractOwner);
        eggsToken.mint(projectOwner, 1_000 ether);
        vm.stopPrank();
    }

    function testCreateProject() public view{
        address owner = projectManagement.getProjectOwner(projectId);
        assertEq(owner, projectOwner);
    }

    function testCreateProjectFailsIfExists() public {
        vm.prank(contractOwner);
        vm.expectRevert("Project already exists");
        projectManagement.createProject(projectId, projectOwner);
    }

    function testCreateCrate() public {
        vm.prank(projectOwner);
        eggsToken.approve(address(projectManagement), 500 ether);
        vm.prank(projectOwner);
        projectManagement.createCrate(projectId, 500 ether);

        (uint256 amount,, bool exists) = projectManagement.getCrate(projectId, 0);
        assertTrue(exists);
        assertEq(amount, 500 ether);
    }

    function testCreateCrateFailsIfNotProjectOwner() public {
        vm.prank(unauthorized);
        vm.expectRevert("Not project owner");
        projectManagement.createCrate(projectId, 100 ether);
    }

    function testAssignEggsToTask() public {
        vm.prank(projectOwner);
        eggsToken.approve(address(projectManagement), 400 ether);
        vm.prank(projectOwner);
        projectManagement.createCrate(projectId, 400 ether);

        vm.prank(projectOwner);
        projectManagement.assignEggsToTask(projectId, 1, 200 ether);

        uint256 assigned = projectManagement.getTaskEggs(projectId, 1);
        assertEq(assigned, 200 ether);
    }

    function testAssignEggsFailsIfNotProjectOwner() public {
        vm.prank(unauthorized);
        vm.expectRevert("Not project owner");
        projectManagement.assignEggsToTask(projectId, 1, 50 ether);
    }

    function testAssignEggsFailsIfInsufficientEggs() public {
        vm.prank(projectOwner);
        eggsToken.approve(address(projectManagement), 100 ether);
        vm.prank(projectOwner);
        projectManagement.createCrate(projectId, 100 ether);

        vm.prank(projectOwner);
        vm.expectRevert();
        projectManagement.assignEggsToTask(projectId, 1, 200 ether);
    }

    function testTotalAvailableEggs() public {
        vm.prank(projectOwner);
        eggsToken.approve(address(projectManagement), 600 ether);
        vm.prank(projectOwner);
        projectManagement.createCrate(projectId, 600 ether);

        uint256 available = projectManagement.totalAvailableEggs(projectId);
        assertEq(available, 600 ether);
    }
}
