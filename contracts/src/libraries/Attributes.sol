// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

interface Attribute {
    function SpendsERC20(
        bytes memory token, // ERC-7930 Address
        bytes memory amountFormula, // Formula (Tagged Union Encoding)
        bytes memory spender // ERC-7930 Address
    )
        external;

    function OnlyBefore(uint256 deadline) external;
    function OnlyFillerUntil(address exclusiveFiller, uint256 deadline) external;
    function OnlyWhenCallResult(
        bytes memory target, // ERC-7930 Address
        bytes4 selector,
        bytes[] memory arguments, // Argument Encoding
        bytes memory result,
        uint256 maxGasCost
    ) external;

    function UnlessRevert(bytes memory reason) external;

    function WithTimestamp(uint256 timestampVarIdx) external;
    function WithBlockNumber(uint256 blockNumberVarIdx) external;
    function WithEffectiveGasPrice(uint256 gasPriceVarIdx) external;
    function WithCallValue(uint256 value) external;
}

library Attributes {
    function SpendsERC20(
        bytes memory token, // ERC-7930 Address
        bytes memory amountFormula, // Formula (Tagged Union Encoding)
        bytes memory spender // ERC-7930 Address
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(Attribute.SpendsERC20, (token, amountFormula, spender));
    }

    function OnlyBefore(uint256 deadline) internal pure returns (bytes memory) {
        return abi.encodeCall(Attribute.OnlyBefore, (deadline));
    }

    function OnlyFillerUntil(address exclusiveFiller, uint256 deadline) internal pure returns (bytes memory) {
        return abi.encodeCall(Attribute.OnlyFillerUntil, (exclusiveFiller, deadline));
    }

    function OnlyWhenCallResult(
        bytes memory target, // ERC-7930 Address
        bytes4 selector,
        bytes[] memory arguments, // Argument Encoding
        bytes memory result,
        uint256 maxGasCost
    ) internal pure returns (bytes memory) {
        return abi.encodeCall(Attribute.OnlyWhenCallResult, (target, selector, arguments, result, maxGasCost));
    }

    function UnlessRevert(bytes memory reason) internal pure returns (bytes memory) {
        return abi.encodeCall(Attribute.UnlessRevert, (reason));
    }

    function WithTimestamp(uint256 timestampVarIdx) internal pure returns (bytes memory) {
        return abi.encodeCall(Attribute.WithTimestamp, (timestampVarIdx));
    }

    function WithBlockNumber(uint256 blockNumberVarIdx) internal pure returns (bytes memory) {
        return abi.encodeCall(Attribute.WithBlockNumber, (blockNumberVarIdx));
    }

    function WithEffectiveGasPrice(uint256 gasPriceVarIdx) internal pure returns (bytes memory) {
        return abi.encodeCall(Attribute.WithEffectiveGasPrice, (gasPriceVarIdx));
    }

    function WithCallValue(uint256 value) internal pure returns (bytes memory) {
        return abi.encodeCall(Attribute.WithCallValue, (value));
    }
}
