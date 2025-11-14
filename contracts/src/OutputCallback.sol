// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

import {IOutputCallback} from "./interfaces/IOutputCallback.sol";
import {IERC20} from "@openzeppelin-contracts-5.5.0/token/ERC20/IERC20.sol";

/**
 * @title OutputCallback
 * @author jacopo.eth, frangio
 * @notice Executes transaction based on provided callback data.
 */
contract OutputCallback is IOutputCallback {
    /// @inheritdoc IOutputCallback
    function outputFilled(bytes32 token, uint256 amount, bytes calldata executionData) external {
        address target = address(bytes20(executionData[0:20]));
        address user = address(bytes20(executionData[20:40]));
        bytes memory data = executionData[40:];

        if (amount != 0) {
            // Approve the tokens to be spent by the target
            IERC20(address(bytes20(token))).approve(target, amount);
        }

        // Try to execute the transaction
        (bool success,) = target.call(data);

        // Reset approval and transfer the tokens back to the user if the transaction fails
        if (!success && amount != 0) {
            IERC20(address(bytes20(token))).approve(target, 0);
            IERC20(address(bytes20(token))).transfer(user, amount);
        }
    }
}
