// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

import {IInputSettlerCompact} from "./interfaces/IInputSettlerCompact.sol";
import {IHyperlaneOracle} from "./interfaces/IHyperlaneOracle.sol";
import {IOutputSettler} from "./interfaces/IOutputSettler.sol";
import {Assumption} from "./types/Assumption.sol";
import {ResolvedOrder} from "./types/ResolvedOrder.sol";
import {SolveParams} from "./types/SolveParams.sol";
import {StandardOrder} from "./types/StandardOrder.sol";
import {Attributes} from "./libraries/Attributes.sol";
import {Formulas} from "./libraries/Formulas.sol";
import {InteroperableAddress} from "./libraries/InteroperableAddress.sol";
import {MandateOutput} from "./libraries/MandateOutputType.sol";
import {Payments} from "./libraries/Payments.sol";
import {StandardOrderType} from "./libraries/StandardOrderType.sol";
import {Steps} from "./libraries/Steps.sol";
import {VariableRoles} from "./libraries/VariableRoles.sol";
import {OrderResolverCompactPayload} from "./types/OrderResolverCompactPayload.sol";

// TODO: Change assumptions comments into requires

/**
 * 1. USER
 * - deposits in the compact and choose an allocator
 *
 * 2. APP
 * - format calldata for contract call --> to be used as callback
 * - calculate funds required to purchase
 * - get a quote from solver/aggregator to know funds required on origin chain
 * - create a StandardOrder for the user
 * - triggers user signature of the compact to use a resource lock -> to generate the
 * - formats the ERC-7683 payload + resolver address -> to be sent to the feed/solver
 *
 * 3. RESOLVER
 * - gets payload
 * - returns ERC-7683 compliant ResolvedOrder payload
 */

contract OrderResolverCompact {
    error ContextOutOfRange();
    error CallOutOfRange();

    uint32 public constant ARBITRUM_CHAINID = 42161;
    uint32 public constant BASE_CHAINID = 8453;

    address public constant HYPERLANE_ORACLE_ARBITRUM = 0x979Ca5202784112f4738403dBec5D0F3B9daabB9;
    address public constant HYPERLANE_ORACLE_BASE = 0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D;

    uint256 public constant GAS_PRICE_BASE = 1e8; // 0.1 gwei
    uint256 public constant GAS_LIMIT = 150_000;

    function variableArgument(uint256 index) internal pure returns (bytes memory) {
        return abi.encode(index);
    }

    function resolve(bytes calldata payload) external view returns (ResolvedOrder memory resolvedOrder) {
        StandardOrder memory order;
        bytes memory sponsorSignature;
        bytes memory allocatorData;

        {
            (OrderResolverCompactPayload memory resolverPayload) = abi.decode(payload, (OrderResolverCompactPayload));

            order = resolverPayload.order;
            sponsorSignature = resolverPayload.sponsorSignature;
            allocatorData = resolverPayload.allocatorData;
        }

        // We assume there is only one output
        require(order.outputs.length == 1, "Only one output is supported");

        // We assume the origin chain is Arbitrum
        require(order.originChainId == ARBITRUM_CHAINID, "Origin chain must be Arbitrum");

        // We assume the output chain is Base
        require(order.outputs[0].chainId == BASE_CHAINID, "Output chain must be Base");

        Assumption[] memory assumptions = new Assumption[](0);
        bytes[] memory payments = new bytes[](order.inputs.length);

        MandateOutput memory output = order.outputs[0];

        bytes32 orderId = StandardOrderType.orderIdentifier(order);

        // Define Steps:
        bytes[] memory steps = new bytes[](3);

        // Step 1: IOutputSettler.fill
        {
            bytes[] memory arguments = new bytes[](4);
            {
                arguments[0] = abi.encode("", orderId);
                arguments[1] = abi.encode("", output);
                arguments[2] = abi.encode("", order.fillDeadline);
                arguments[3] = variableArgument(0); // filler's chosen recipient address will be the first variable
            }

            bytes[] memory attributes = new bytes[](2);
            {
                attributes[0] = Attributes.OnlyBefore(order.fillDeadline);
                attributes[1] = Attributes.SpendsERC20(
                    InteroperableAddress.formatEvmV1(output.chainId, address(bytes20(output.token))),
                    /// @dev We assume `output.amount` is a constant
                    Formulas.Const(output.amount),
                    /// @dev We assume `output.settler` is a known supported output settler
                    InteroperableAddress.formatEvmV1(output.chainId, address(bytes20(output.settler)))
                );
            }

            steps[0] = Steps.Call(
                InteroperableAddress.formatEvmV1(output.chainId, address(bytes20(output.settler))),
                IOutputSettler.fill.selector,
                arguments,
                attributes,
                new uint256[](0),
                new bytes[](0)
            );
        }

        // Step 2: IHyperlaneOracle.submit
        {
            bytes[] memory arguments = new bytes[](6);
            {
                arguments[0] = abi.encode("", uint32(order.originChainId));
                arguments[1] = abi.encode("", HYPERLANE_ORACLE_ARBITRUM);
                arguments[2] = abi.encode("", GAS_LIMIT);
                arguments[3] = abi.encode("", new bytes(0)); // customMetadata
                arguments[4] = abi.encode("", output.settler); // source
                arguments[5] = variableArgument(2);
            }

            bytes[] memory attributes = new bytes[](1);
            {
                // Gas needed to cover execution on destination chain. We assume a gasPrice of 0.1 gwei
                attributes[0] = Attributes.WithCallValue(GAS_PRICE_BASE * GAS_LIMIT);
            }

            uint256[] memory dependencySteps = new uint256[](1);
            dependencySteps[0] = 0;

            steps[1] = Steps.Call(
                InteroperableAddress.formatEvmV1(output.chainId, address(bytes20(HYPERLANE_ORACLE_BASE))),
                IHyperlaneOracle.submit.selector,
                arguments,
                attributes,
                dependencySteps,
                new bytes[](0)
            );
        }

        // Step 3: IInputSettlerCompact.finalise
        {
            bytes[] memory arguments = new bytes[](5);
            {
                arguments[0] = abi.encode("", order);
                arguments[1] = abi.encode("", abi.encode(sponsorSignature, allocatorData));
                arguments[2] = variableArgument(3); // solveParams
                arguments[3] = variableArgument(0); // solver
                arguments[4] = abi.encode("", new bytes(0)); // call
            }

            bytes[] memory attributes = new bytes[](1);
            {
                bytes[] memory isProvenArguments = new bytes[](4);
                {
                    isProvenArguments[0] = abi.encode("", output.chainId);
                    isProvenArguments[1] = abi.encode("", HYPERLANE_ORACLE_BASE);
                    isProvenArguments[2] = abi.encode("", output.settler);
                    isProvenArguments[3] = variableArgument(4); // dataHash
                }

                attributes[0] = Attributes.OnlyWhenCallResult(
                    InteroperableAddress.formatEvmV1(order.originChainId, address(bytes20(HYPERLANE_ORACLE_ARBITRUM))),
                    IHyperlaneOracle.isProven.selector,
                    isProvenArguments,
                    abi.encode(true),
                    150_000 // The amount of gas needed to cover the execution on isProven
                );
            }

            // Set payments
            for (uint256 i; i < order.inputs.length; ++i) {
                uint256[2] memory input = order.inputs[i];
                address inputToken = address(uint160(input[0]));
                uint256 inputAmount = input[1];

                payments[i] = Payments.ERC20(
                    InteroperableAddress.formatEvmV1(order.originChainId, inputToken),
                    Formulas.Const(inputAmount),
                    0, // recipientVarIdx
                    0 // estimatedDelaySeconds
                );
            }

            uint256[] memory dependencySteps = new uint256[](1);
            dependencySteps[0] = 1;

            steps[2] = Steps.Call(
                InteroperableAddress.formatEvmV1(order.originChainId, address(bytes20(output.settler))),
                IInputSettlerCompact.finalise.selector,
                arguments,
                attributes,
                dependencySteps,
                payments
            );
        }

        // Define Variable Roles:
        // 1. Payment recipient
        // 2. Timestamp
        // 3. Oracle Payload
        // 4. Solve Params
        // 5. Data Hash
        bytes[] memory variables = new bytes[](5);
        {
            variables[0] = VariableRoles.PaymentRecipient(order.originChainId);
            variables[1] = VariableRoles.TxOutput();

            bytes[] memory queryArguments = new bytes[](8);
            queryArguments[0] = variableArgument(0);
            queryArguments[1] = abi.encode("", orderId);
            queryArguments[2] = variableArgument(1);
            queryArguments[3] = abi.encode("", output.token);
            queryArguments[4] = abi.encode("", output.amount);
            queryArguments[5] = abi.encode("", output.recipient);
            queryArguments[6] = abi.encode("", output.callbackData);
            queryArguments[7] = abi.encode("", output.context);

            variables[2] = VariableRoles.Query(
                InteroperableAddress.formatEvmV1(address(this)),
                OrderResolverCompact.encodeOraclePayload.selector,
                queryArguments,
                block.number
            );

            queryArguments = new bytes[](2);
            queryArguments[0] = variableArgument(1); // timestamp
            queryArguments[1] = variableArgument(0); // solver

            variables[3] = VariableRoles.Query(
                InteroperableAddress.formatEvmV1(address(this)),
                OrderResolverCompact.encodeSolveParams.selector,
                queryArguments,
                block.number
            );

            queryArguments = new bytes[](1);
            queryArguments[0] = variableArgument(2); // encodedOraclePayload

            variables[4] = VariableRoles.Query(
                InteroperableAddress.formatEvmV1(address(this)),
                OrderResolverCompact.encodeDataHash.selector,
                queryArguments,
                block.number
            );
        }

        // Payments empty as they're already specified in the finalise step
        resolvedOrder = ResolvedOrder(steps, variables, assumptions, new bytes[](0));
    }

    /**
     * @notice dataHash encoding.
     */
    function encodeDataHash(bytes memory encodedOraclePayload) external pure returns (bytes memory) {
        return abi.encode("", keccak256(encodedOraclePayload));
    }

    /**
     * @notice FillDescription encoding.
     */
    function encodeSolveParams(uint32 timestamp, bytes32 solver) external pure returns (bytes memory) {
        bytes[] memory encodedOutput = new bytes[](1);

        SolveParams[] memory solveParams = new SolveParams[](1);
        solveParams[0] = SolveParams(timestamp, solver);

        return abi.encode("", encodedOutput);
    }

    /**
     * @notice FillDescription encoding.
     * @dev The encoding scheme uses 2 bytes long length identifiers. As a result, neither call nor context exceed
     * 65'535 bytes.
     */
    function encodeOraclePayload(
        bytes32 solver,
        bytes32 orderId,
        uint32 timestamp,
        bytes32 token,
        uint256 amount,
        bytes32 recipient,
        bytes calldata callbackData,
        bytes calldata context
    ) external pure returns (bytes memory) {
        if (callbackData.length > type(uint16).max) revert CallOutOfRange();
        if (context.length > type(uint16).max) revert ContextOutOfRange();

        bytes[] memory encodedOutput = new bytes[](1);

        encodedOutput[0] = abi.encodePacked(
            solver,
            orderId,
            timestamp,
            token,
            amount,
            recipient,
            uint16(callbackData.length), // To protect against data collisions
            callbackData,
            uint16(context.length), // To protect against data collisions
            context
        );

        return abi.encode("", encodedOutput);
    }
}
