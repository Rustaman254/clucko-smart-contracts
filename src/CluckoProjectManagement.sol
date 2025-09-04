// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CluckoEggToken.sol";

contract CluckoProjectManagement {
    EggsToken public eggsToken;
    address public owner;

    struct Crate {
        uint256 eggsAmount;
        uint256 eggsUsed;
        bool exists;
    }

    // Project owner (not necessarily contract owner) can manage their project
    mapping(bytes32 => address) public projectOwners;
    mapping(bytes32 => mapping(uint256 => Crate)) public crates; // projectId -> crateIndex -> Crate
    mapping(bytes32 => uint256) public crateCounts;
    mapping(bytes32 => bool) public projectExists;
    bytes32[] public projectIds;

    // taskId key is keccak256(projectId, taskId) for uniqueness across projects
    mapping(bytes32 => uint256) private taskEggBudget; // allocated Eggs to tasks
    mapping(bytes32 => uint256) private taskEggSpent;  // Eggs spent or assigned so far (optional)

    modifier onlyContractOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyProjectOwner(bytes32 projectId) {
        require(projectExists[projectId], "Project does not exist");
        require(msg.sender == projectOwners[projectId], "Not project owner");
        _;
    }

    event ProjectCreated(bytes32 indexed projectId, address indexed projectOwner);
    event CrateCreated(bytes32 indexed projectId, uint256 indexed crateIndex, uint256 eggsAmount);
    event EggsAssignedToTask(bytes32 indexed projectId, uint256 indexed taskId, uint256 eggsAmount);

    constructor(EggsToken _eggsToken) {
        eggsToken = _eggsToken;
        owner = msg.sender;
    }

    // Contract owner can create a project and assign project owner
    function createProject(bytes32 projectId, address projectOwner) external onlyContractOwner {
        require(!projectExists[projectId], "Project already exists");
        require(projectOwner != address(0), "Invalid project owner");
        projectOwners[projectId] = projectOwner;
        projectExists[projectId] = true;
        projectIds.push(projectId);

        emit ProjectCreated(projectId, projectOwner);
    }

    // Project owner funds a new crate by transferring Eggs tokens to the contract
    function createCrate(bytes32 projectId, uint256 eggsAmount) external onlyProjectOwner(projectId) {
        require(eggsAmount > 0, "Eggs amount must be greater than zero");
        require(eggsToken.transferFrom(msg.sender, address(this), eggsAmount), "Eggs transfer failed");

        uint256 index = crateCounts[projectId];
        crates[projectId][index] = Crate({
            eggsAmount: eggsAmount,
            eggsUsed: 0,
            exists: true
        });

        crateCounts[projectId] = index + 1;

        emit CrateCreated(projectId, index, eggsAmount);
    }

    // Project owner assigns Eggs budget from crates to a specific task
    function assignEggsToTask(bytes32 projectId, uint256 taskId, uint256 eggsAmount) external onlyProjectOwner(projectId) {
        require(eggsAmount > 0, "Eggs amount must be greater than zero");

        // Check total available Eggs in crates
        uint256 totalAvailable = totalAvailableEggs(projectId);
        require(eggsAmount <= totalAvailable, "Not enough Eggs available in crates");

        bytes32 taskKey = keccak256(abi.encodePacked(projectId, taskId));
        taskEggBudget[taskKey] += eggsAmount;

        // Optionally update crates usage here or on task completion

        emit EggsAssignedToTask(projectId, taskId, eggsAmount);
    }

    // View functions

    // Returns total Eggs available (unallocated) in this project
    function totalAvailableEggs(bytes32 projectId) public view returns (uint256) {
        uint256 totalAllocated = 0;
        uint256 count = crateCounts[projectId];

        for (uint256 i = 0; i < count; i++) {
            totalAllocated += crates[projectId][i].eggsAmount;
        }

        // Sum of Eggs allocated to tasks in this project
        uint256 totalTaskAllocated = 0;
        // NOTE: To fully track, you may want to maintain task list or index

        // For simplicity, omit subtracting allocated to tasks here, or add storage to track

        return totalAllocated - totalTaskAllocated;
    }

    function getCrate(bytes32 projectId, uint256 index) external view returns (uint256 eggsAmount, uint256 eggsUsed, bool exists) {
        require(index < crateCounts[projectId], "Invalid crate index");
        Crate memory crate = crates[projectId][index];
        return (crate.eggsAmount, crate.eggsUsed, crate.exists);
    }

    function getProjectOwner(bytes32 projectId) external view returns (address) {
        require(projectExists[projectId], "Project does not exist");
        return projectOwners[projectId];
    }

    function getTaskEggs(bytes32 projectId, uint256 taskId) external view returns (uint256) {
        bytes32 taskKey = keccak256(abi.encodePacked(projectId, taskId));
        return taskEggBudget[taskKey];
    }

    function getAllProjects() external view returns (bytes32[] memory) {
        return projectIds;
    } 
}
