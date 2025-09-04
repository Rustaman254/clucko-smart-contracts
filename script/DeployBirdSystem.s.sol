// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

import "../src/CluckoEggToken.sol";
import "../src/FeedsToken.sol";
import "../src/CluckoChickToken.sol";
import "../src/MatureBird.sol";
import "../src/BirdLifecycleAndProjectManager.sol";

contract DeployBirdSystem is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        EggsToken eggs = new EggsToken();
        FeedsToken feeds = new FeedsToken();
        ChickToken chicks = new ChickToken();
        MatureBirdNFT matureBird = new MatureBirdNFT();

        BirdLifecycleAndProjectManager manager = new BirdLifecycleAndProjectManager(
            address(chicks),
            address(matureBird),
            address(feeds),
            address(eggs)
        );

        chicks.transferOwnership(address(manager));
        feeds.transferOwnership(address(manager));
        matureBird.transferOwnership(address(manager));
        eggs.transferOwnership(address(manager));

        vm.stopBroadcast();

        console.log("EggsToken:", address(eggs));
        console.log("FeedsToken:", address(feeds));
        console.log("ChickToken:", address(chicks));
        console.log("MatureBirdNFT:", address(matureBird));
        console.log("Manager:", address(manager));
    }
}
