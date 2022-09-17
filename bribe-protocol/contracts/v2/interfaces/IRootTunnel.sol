// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRootTunnel {
    function deposit(
        address rootToken,
        address user,
        uint256 amount,
        bytes calldata data
    ) external;

    function sendBidInfo(
        string calldata poolName,
        uint256 bidAmount,
        uint256 proposalStartBlock,
        uint256 totalVotes,
        uint256 proposalId
    ) external;

    function sendReceiptTokenSnapshot(
        string calldata poolName,
        address from,
        address to,
        uint256 fromBalance,
        uint256 toBalance,
        uint256 transferAmount,
        uint256 blockNumber
    ) external;

    function mapToken(address rootToken) external;
}
