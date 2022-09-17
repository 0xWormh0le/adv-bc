// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

abstract contract BaseRootTunnel {
    // state sender contract
    IFxStateSender public immutable fxRoot;

    // child tunnel contract which receives and sends messages
    address public fxChildTunnel;

    address public pool;

    address public asset;

    bytes32 public constant BID_INFO = keccak256("BID_INFO");

    bytes32 public constant RECEIPT_SNAPSHOT = keccak256("RECEIPT_SNAPSHOT");

    constructor(address _fxRoot) {
        fxRoot = IFxStateSender(_fxRoot);
    }

    // set fxChildTunnel if not set already
    function setFxChildTunnel(address _fxChildTunnel) external {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        fxChildTunnel = _fxChildTunnel;
    }

    function setPool(address _pool) external {
        require(pool == address(0), "FxBaseRootTunnel: POOL_ALREADY_SET");
        pool = _pool;
    }

    function setAsset(address _asset) external {
        require(asset == address(0), "FxBaseRootTunnel: POOL_ALREADY_SET");
        asset = _asset;
    }

    function sendBidInfo(
        string calldata poolName,
        uint256 bidAmount,
        uint256 proposalStartBlock,
        uint256 totalVotes,
        uint256 proposalId
    ) external {
        require(msg.sender == pool, "FxBaseRootTunnel: FROM_POOL");
        _sendMessageToChild(
            abi.encode(BID_INFO, poolName, bidAmount, proposalStartBlock, totalVotes, proposalId)
        );
    }

    function sendReceiptTokenSnapshot(
        string calldata poolName,
        address from,
        address to,
        uint256 fromBalance,
        uint256 toBalance,
        uint256 transferAmount,
        uint256 blockNumber
    ) external {
        require(msg.sender == asset, "FxBaseRootTunnel: FROM_RECEIPT_TOKEN");
        _sendMessageToChild(
            abi.encode(
                RECEIPT_SNAPSHOT,
                poolName,
                from,
                to,
                fromBalance,
                toBalance,
                transferAmount,
                blockNumber
            )
        );
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }
}
