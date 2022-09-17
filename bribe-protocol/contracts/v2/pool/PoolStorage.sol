//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IBribeRewardGauge.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/IRootTunnel.sol";

abstract contract PoolStorage is IPool {
    /// @dev pool name
    string public override name;

    /// @dev bidders will bid with bidAsset e.g. usdc
    IERC20 public immutable bidAsset;

    /// @dev receipt token
    IAsset public immutable override asset;

    /// @dev root tunnel contract
    IRootTunnel public immutable override rootTunnel;

    /// @dev current bid ends at proposal.endBlock - endBidFromProposal
    uint256 public endBidFromProposal;

    /// @dev proposal id to bid information
    mapping(uint256 => Bid) public bids;

    /// @dev blocked proposals
    mapping(uint256 => bool) public blockedProposals;

    /// @dev user => proposal => bool
    mapping(address => mapping(uint256 => bool)) internal userBids;

    /**
     * @dev constructor
     * @param name_ pool name
     * @param bidAsset_ bid asset
     * @param asset_ receipt token
     * @param rootTunnel_ root tunnel contract
     */
    constructor(
        string memory name_,
        address bidAsset_,
        address rootTunnel_,
        address asset_
    ) {
        require(address(bidAsset_) != address(0), "BID_ASSET");
        require(asset_ != address(0), "invalid asset address");
        require(rootTunnel_ != address(0), "invalid root tunnel");

        name = name_;
        bidAsset = IERC20(bidAsset_);
        asset = IAsset(asset_);
        rootTunnel = IRootTunnel(rootTunnel_);
        endBidFromProposal = 100;
    }
}
