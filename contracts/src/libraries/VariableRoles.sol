// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

interface VariableRole {
    function PaymentRecipient(uint256 chainId) external;
    function PaymentChain() external;
    function Pricing() external;
    function TxOutput() external;
    function Witness(string memory kind, bytes memory data, uint256[] memory variables) external;
    function Query(bytes memory target, bytes4 selector, bytes[] memory arguments, uint256 blockNumber) external;
}

library VariableRoles {
    function PaymentRecipient(uint256 chainId) internal pure returns (bytes memory) {
        return abi.encodeCall(VariableRole.PaymentRecipient, (chainId));
    }

    function PaymentChain() internal pure returns (bytes memory) {
        return abi.encodeCall(VariableRole.PaymentChain, ());
    }

    function Pricing() internal pure returns (bytes memory) {
        return abi.encodeCall(VariableRole.Pricing, ());
    }

    function TxOutput() internal pure returns (bytes memory) {
        return abi.encodeCall(VariableRole.TxOutput, ());
    }

    function Witness(string memory kind, bytes memory data, uint256[] memory variables)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(VariableRole.Witness, (kind, data, variables));
    }

    function Query(bytes memory target, bytes4 selector, bytes[] memory arguments, uint256 blockNumber)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(VariableRole.Query, (target, selector, arguments, blockNumber));
    }
}
