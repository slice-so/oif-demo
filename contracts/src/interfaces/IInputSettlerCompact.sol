// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

import {OrderPurchase} from "../types/OrderPurchaseType.sol";
import {StandardOrder} from "../types/StandardOrder.sol";
import {SolveParams} from "../types/SolveParams.sol";

interface IInputSettlerCompact {
    /**
     * @notice Finalises an order when called directly by the solver
     * @dev The caller must be the address corresponding to the first solver in the solvers array.
     * @param order StandardOrder signed in conjunction with a Compact to form an order
     * @param signatures A signature for the sponsor and the allocator. abi.encode(bytes(sponsorSignature),
     * bytes(allocatorData))
     * @param solveParams List of solve parameters for when the outputs were filled
     * @param destination Where to send the inputs. If the solver wants to send the inputs to themselves, they should
     * pass their address to this parameter.
     * @param call Optional callback data. If non-empty, will call orderFinalised on the destination
     */
    function finalise(
        StandardOrder calldata order,
        bytes calldata signatures,
        SolveParams[] calldata solveParams,
        bytes32 destination,
        bytes calldata call
    ) external;

    function finaliseWithSignature(
        StandardOrder calldata order,
        bytes calldata signatures,
        SolveParams[] calldata solveParams,
        bytes32 destination,
        bytes calldata call,
        bytes calldata orderOwnerSignature
    ) external;

    function orderIdentifier(StandardOrder memory order) external view returns (bytes32);

    function purchaseOrder(
        OrderPurchase memory orderPurchase,
        StandardOrder memory order,
        bytes32 orderSolvedByIdentifier,
        bytes32 purchaser,
        uint256 expiryTimestamp,
        bytes memory solverSignature
    ) external;
}
