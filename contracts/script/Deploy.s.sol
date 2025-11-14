// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {OrderResolverCompact} from "../src/OrderResolverCompact.sol";

contract Deploy is Script {
    function run() external returns (OrderResolverCompact) {
        vm.startBroadcast();

        OrderResolverCompact resolver = new OrderResolverCompact();

        vm.stopBroadcast();

        return resolver;
    }
}

