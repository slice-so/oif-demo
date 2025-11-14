// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

import {MandateOutput} from "../libraries/MandateOutputType.sol";

struct StandardOrder {
    address user;
    uint256 nonce;
    uint256 originChainId;
    uint32 expires;
    uint32 fillDeadline;
    address inputOracle;
    uint256[2][] inputs;
    MandateOutput[] outputs;
}
