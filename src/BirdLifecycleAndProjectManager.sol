// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IChickToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface IMatureBirdNFT {
    function mint(address to, string calldata tokenURI) external returns (uint256);
}

interface IFeedsToken {
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

interface IEggsToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract BirdLifecycleAndProjectManager is Ownable {
    IChickToken public chickToken;
    IMatureBirdNFT public matureBirdNFT;
    IFeedsToken public feedsToken;
    IEggsToken public eggsToken;

    uint256 public incubationPeriod = 3 days;
    uint256 public feedsPerFeeding = 10 * 10**18;
    uint256 public projectCreationCost = 100 * 10**18;

    // Basket renamed from crate
    struct Basket {
        uint256 eggsAmount;
        uint256 eggsSpent;
        bool exists;
    }

    struct Project {
        address owner;
        uint256 basketCount;
        mapping(uint256 => Basket) baskets;
        bool exists;
    }

    uint256 public projectCount;
    mapping(uint256 => Project) public projects;
    uint256[] public projectIds; 

    modifier onlyOwnerOf(uint256 projectId) {
        require(msg.sender == projects[projectId].owner, "Not owner");
        _;
    }

    struct ChickInfo {
        uint256 hatchedTimestamp;
        uint256 lastFedTimestamp;
        uint256 feedingsCount;
        string species;
        string metadataURI;
        bool exists;
    }

    mapping(address => ChickInfo[]) public userChicks;

    // Events
    event ProjectCreated(uint256 indexed projectId, address indexed owner);
    event BasketPurchased(uint256 indexed projectId, uint256 basketIndex, uint256 eggsAmount);
    event EggsAssignedToTask(uint256 indexed projectId, uint256 eggsAmount);
    event EggHatched(address indexed user, uint256 chickIndex, string species);
    event ChickFed(address indexed user, uint256 chickIndex, uint256 feedingsCount);
    event ChickMatured(address indexed user, uint256 chickIndex, uint256 nftTokenId);

    constructor(
        address _chickToken,
        address _matureBirdNFT,
        address _feedsToken,
        address _eggsToken
    ) Ownable(msg.sender) {
        chickToken = IChickToken(_chickToken);
        matureBirdNFT = IMatureBirdNFT(_matureBirdNFT);
        feedsToken = IFeedsToken(_feedsToken);
        eggsToken = IEggsToken(_eggsToken);
    }

    // Project Creation using eggs tokens
    function createProject() external {
        require(eggsToken.balanceOf(msg.sender) >= projectCreationCost, "Insufficient eggs to create project");
        require(eggsToken.transferFrom(msg.sender, address(this), projectCreationCost), "Eggs transfer failed");

        projectCount++;
        Project storage p = projects[projectCount];
        p.owner = msg.sender;
        p.exists = true;

        projectIds.push(projectCount); 

        emit ProjectCreated(projectCount, msg.sender);
    }

    // Purchase basket for eggs budget in project
    function purchaseBasket(uint256 projectId, uint256 eggsAmount) external {
        Project storage p = projects[projectId];
        require(p.exists, "Project not found");
        require(p.owner == msg.sender, "Not project owner");
        require(eggsToken.balanceOf(msg.sender) >= eggsAmount, "Insufficient eggs");
        require(eggsToken.transferFrom(msg.sender, address(this), eggsAmount), "Eggs transfer failed");

        p.basketCount++;
        p.baskets[p.basketCount] = Basket({
            eggsAmount: eggsAmount,
            eggsSpent: 0,
            exists: true
        });

        emit BasketPurchased(projectId, p.basketCount, eggsAmount);
    }

    // Returns total available eggs in a project
    function totalAvailableEggs(uint256 projectId) public view returns (uint256) {
        Project storage p = projects[projectId];
        require(p.exists, "Project not found");

        uint256 totalAvailable = 0;
        for (uint256 i = 1; i <= p.basketCount; i++) {
            Basket storage b = p.baskets[i];
            if (b.exists) {
                totalAvailable += (b.eggsAmount - b.eggsSpent);
            }
        }
        return totalAvailable;
    }

    // Assign eggs from baskets to tasks in project
    function assignEggsToTask(uint256 projectId, uint256 eggsAmount) external {
        Project storage p = projects[projectId];
        require(p.exists, "Project not found");
        require(p.owner == msg.sender, "Not project owner");

        uint256 available = totalAvailableEggs(projectId);
        require(available >= eggsAmount, "Not enough eggs available");

        uint256 remaining = eggsAmount;
        for (uint256 i = 1; i <= p.basketCount; i++) {
            Basket storage b = p.baskets[i];
            if (b.exists) {
                uint256 availableInBasket = b.eggsAmount - b.eggsSpent;
                if (availableInBasket >= remaining) {
                    b.eggsSpent += remaining;
                    remaining = 0;
                    break;
                } else {
                    b.eggsSpent = b.eggsAmount;
                    remaining -= availableInBasket;
                }
            }
        }
        require(remaining == 0, "Allocation failed");

        emit EggsAssignedToTask(projectId, eggsAmount);
    }

    // Hatch eggs into chicks - mints chick tokens and records chick info
    function hatchEgg(
        address user,
        string calldata species,
        string calldata metadataURI,
        uint256 chicksAmount
    ) external onlyOwner {
        require(chicksAmount > 0, "Must hatch at least one chick");

        for (uint256 i = 0; i < chicksAmount; i++) {
            userChicks[user].push(
                ChickInfo({
                    hatchedTimestamp: block.timestamp,
                    lastFedTimestamp: 0,
                    feedingsCount: 0,
                    species: species,
                    metadataURI: metadataURI,
                    exists: true
                })
            );
        }

        chickToken.mint(user, chicksAmount);

        emit EggHatched(user, userChicks[user].length - 1, species);
    }

    // Feed a specific chick by user; burns feeds tokens
    function feedChick(uint256 chickIndex) external {
        require(chickIndex < userChicks[msg.sender].length, "Invalid index");
        ChickInfo storage chick = userChicks[msg.sender][chickIndex];
        require(chick.exists, "Chick does not exist");

        require(feedsToken.balanceOf(msg.sender) >= feedsPerFeeding, "Insufficient feeds");
        feedsToken.burnFrom(msg.sender, feedsPerFeeding);

        chick.feedingsCount++;
        chick.lastFedTimestamp = block.timestamp;

        emit ChickFed(msg.sender, chickIndex, chick.feedingsCount);
    }

    // Mature chick to mature bird NFT
    function matureChick(uint256 chickIndex) external {
        require(chickIndex < userChicks[msg.sender].length, "Invalid index");
        ChickInfo storage chick = userChicks[msg.sender][chickIndex];
        require(chick.exists, "Chick does not exist");
        require(block.timestamp >= chick.hatchedTimestamp + incubationPeriod, "Incubation not complete");
        require(chick.feedingsCount >= 5, "Insufficient feeding");

        chickToken.burn(msg.sender, 1);

        uint256 tokenId = matureBirdNFT.mint(msg.sender, chick.metadataURI);

        chick.exists = false;

        emit ChickMatured(msg.sender, chickIndex, tokenId);
    }

    // Get chick count of user
    function getChicksCount(address user) external view returns (uint256) {
        return userChicks[user].length;
    }

    // Get info for user's chick by index
    function getChickInfo(address user, uint256 index) external view returns (
        uint256 hatchedTimestamp,
        uint256 lastFedTimestamp,
        uint256 feedingsCount,
        string memory species,
        string memory metadataURI,
        bool exists
    ) {
        ChickInfo storage chick = userChicks[user][index];
        return (
            chick.hatchedTimestamp,
            chick.lastFedTimestamp,
            chick.feedingsCount,
            chick.species,
            chick.metadataURI,
            chick.exists
        );
    }

    // Config setters
    function setIncubationPeriod(uint256 period) external onlyOwner {
        incubationPeriod = period;
    }

    function setFeedsPerFeeding(uint256 amount) external onlyOwner {
        feedsPerFeeding = amount;
    }

    function setProjectCreationCost(uint256 cost) external onlyOwner {
        projectCreationCost = cost;
    }

    function getAllProjects() external view returns (uint256[] memory) {
        return projectIds;
    }
}