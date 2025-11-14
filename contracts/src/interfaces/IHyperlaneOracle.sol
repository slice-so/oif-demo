// SPDX-License-Identifier: CC0
pragma solidity 0.8.30;

interface IHyperlaneOracle {
    /**
     * @notice Takes proofs that have been marked as valid by a source and dispatches them to Hyperlane's Mailbox for
     * broadcast.
     * @param destinationDomain The domain to which the message is sent.
     * @param recipientOracle The address of the oracle on the destination domain.
     * @param gasLimit Gas limit for the message.
     * @param customMetadata Additional metadata to include in the standard hook metadata.
     * @param source Application that has payloads that are marked as valid.
     * @param payloads List of payloads to broadcast.
     */
    function submit(
        uint32 destinationDomain,
        address recipientOracle,
        uint256 gasLimit,
        bytes calldata customMetadata,
        address source,
        bytes[] calldata payloads
    ) external payable;

    /**
     * @notice Check if some data has been attested to on some chain.
     * @param remoteChainId ChainId of data origin.
     * @param remoteOracle Attestor on the data origin chain.
     * @param application Application that the data originated from.
     * @param dataHash Hash of data.
     * @return bool Whether the hashed data has been attested to.
     */
    function isProven(uint256 remoteChainId, bytes32 remoteOracle, bytes32 application, bytes32 dataHash)
        external
        view
        returns (bool);
}
