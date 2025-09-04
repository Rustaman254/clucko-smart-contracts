// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { ChickToken } from "../src/CluckoChickToken.sol";

contract CluckoChickTokenScript is Script {
    function run() external {
        vm.startBroadcast();
        new ChickToken();
        vm.stopBroadcast();
    }
}