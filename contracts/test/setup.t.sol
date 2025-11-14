// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {OrderResolverCompact} from "../src/OrderResolverCompact.sol";
import {StandardOrder} from "../src/types/StandardOrder.sol";
import {MandateOutput} from "../src/libraries/MandateOutputType.sol";

contract SetupTest is Test {
    OrderResolverCompact resolver;

    uint32 constant ARBITRUM_CHAINID = 42161;
    uint32 constant BASE_CHAINID = 8453;
    address constant HYPERLANE_ORACLE_BASE = 0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D;

    function setUp() public {
        resolver = new OrderResolverCompact();
    }

    // Helper function to create a valid order
    function _createValidOrder() internal view returns (StandardOrder memory) {
        MandateOutput[] memory outputs = new MandateOutput[](1);
        outputs[0] = MandateOutput({
            oracle: bytes32(uint256(uint160(HYPERLANE_ORACLE_BASE))),
            settler: bytes32(uint256(uint160(address(0x1234)))),
            chainId: BASE_CHAINID,
            token: bytes32(uint256(uint160(address(0x5678)))),
            amount: 1000,
            recipient: bytes32(uint256(uint160(address(0x9abc)))),
            callbackData: hex"abcd",
            context: hex"ef01"
        });

        uint256[2][] memory inputs = new uint256[2][](1);
        uint256[2] memory input;
        input[0] = uint256(uint160(address(0x5678)));
        input[1] = 1000;
        inputs[0] = input;

        return StandardOrder({
            user: address(0x1111),
            nonce: 1,
            originChainId: ARBITRUM_CHAINID,
            expires: uint32(block.timestamp + 3600),
            fillDeadline: uint32(block.timestamp + 1800),
            inputOracle: address(0x2222),
            inputs: inputs,
            outputs: outputs
        });
    }
}
