// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {OutputCallback} from "../src/OutputCallback.sol";

contract Deploy is Script {
    function run() external returns (OutputCallback) {
        vm.startBroadcast();

        OutputCallback outputCallback = new OutputCallback();

        vm.stopBroadcast();

        return outputCallback;
    }
}

