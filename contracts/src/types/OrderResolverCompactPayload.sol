// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

import {StandardOrder} from "./StandardOrder.sol";

struct OrderResolverCompactPayload {
    StandardOrder order;
    bytes sponsorSignature;
    bytes allocatorData;
}
