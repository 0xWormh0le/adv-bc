//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAsset.sol";

abstract contract BidPotStorage {
    struct Bid {
        uint256 bidAmount;
        uint256 proposalStartBlock;
        uint256 totalVotes;
    }

    struct UserRewardBidInfo {
        // reward from the bids in the bribe pool
        uint256 totalPendingBidReward;
        // tracks the last user bid id for deposit
        uint256 lastRewardBidId;
    }

    /// @dev fee precision
    uint64 internal constant FEE_PRECISION = 10000;

    /// @dev fee percentage share is 16%
    uint128 internal constant FEE_PERCENTAGE = 1600;

    /// @dev feeRecipient address to send received fees to
    address public feeRecipient;

    /// @dev fees received
    mapping(string => uint256) public feesReceived;

    /// @dev bid id counter for each proposal voted
    mapping(string => uint256) public currentBidRewardCount;

    /// @dev bidders will bid with bidAsset e.g. usdc
    mapping(string => IERC20) public bidAsset;

    /// @dev proposal id to bid information
    mapping(string => mapping(uint256 => Bid)) public bids;

    /// @dev bid id to proposal id
    mapping(string => mapping(uint256 => uint256)) internal bidIdToProposalId;

    /// @dev user info
    mapping(string => mapping(address => UserRewardBidInfo)) internal userRewardBids;

    event RewardAccrue(
        string poolName,
        address indexed user,
        uint256 pendingBidReward,
        uint256 timestamp
    );

    event RewardClaim(string poolName, address indexed user, uint256 pendingBid, uint256 timestamp);

    event RewardDistributed(string poolName, uint256 proposalId, uint256 amount);

    event WithdrawFees(
        string poolName,
        address indexed sender,
        uint256 feesReceived,
        uint256 timestamp
    );

    /**
     * @dev constructor
     * @param feeRecipient_ fee recipient
     */
    constructor(address feeRecipient_) {
        require(feeRecipient_ != address(0), "FEE_RECEIPIENT");

        feeRecipient = feeRecipient_;
    }
}
