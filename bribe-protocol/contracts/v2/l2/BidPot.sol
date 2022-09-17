//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../tunnels/ChildTunnel.sol";
import "../tunnels/ChildTokenReceiver.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/IRootTunnel.sol";
import "./BidPotStorage.sol";
import "./Snapshot.sol";

contract BidPot is
    ChildTunnel,
    ChildTokenReceiver,
    BidPotStorage,
    ReceiptTokenSnapshot,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    bytes32 public constant BID_INFO = keccak256("BID_INFO");

    bytes32 public constant RECEIPT_SNAPSHOT = keccak256("RECEIPT_SNAPSHOT");

    constructor(
        address fxChild_,
        address _tokenTemplate,
        address feeRecipient_
    ) ChildTunnel(fxChild_) ChildTokenReceiver(_tokenTemplate) BidPotStorage(feeRecipient_) {}

    /**
     * @dev  _calculateFeeAmount calculate the fee percentage share
     */
    function _calculateFeeAmount(uint256 amount) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * FEE_PERCENTAGE) / FEE_PRECISION;
    }

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (bytes32 header, bytes memory data) = abi.decode(message, (bytes32, bytes));

        if (header == DEPOSIT) {
            _syncDeposit(data);
        } else if (header == MAP_TOKEN) {
            _mapToken(data);
        } else if (header == BID_INFO) {
            (
                string memory pool,
                uint256 bidAmount,
                uint256 proposalStartBlock,
                uint256 totalVotes,
                uint256 proposalId
            ) = abi.decode(data, (string, uint256, uint256, uint256, uint256));
            _distributeRewards(pool, bidAmount, proposalStartBlock, totalVotes, proposalId);
        } else if (header == RECEIPT_SNAPSHOT) {
            (
                string memory pool,
                address from,
                address to,
                uint256 fromBalance,
                uint256 toBalance,
                uint256 transferAmount,
                uint256 blockNumber
            ) = abi.decode(data, (string, address, address, uint256, uint256, uint256, uint256));
            _tokenTransfer(pool, from, to, fromBalance, toBalance, transferAmount, blockNumber);
        }
    }

    /**
     * @dev distribute rewards for the proposal
     * @notice called in children's vote function (after bidding process ended)
     * @param proposalId id of proposal to distribute rewards fo
     */
    function _distributeRewards(
        string memory pool,
        uint256 bidAmount,
        uint256 proposalStartBlock,
        uint256 totalVotes,
        uint256 proposalId
    ) internal {
        // distribute rewards
        Bid storage bid = bids[pool][proposalId];

        bid.bidAmount = bidAmount;
        bid.proposalStartBlock = proposalStartBlock;
        bid.totalVotes = totalVotes;

        uint256 feeAmount = _calculateFeeAmount(bidAmount);

        feesReceived[pool] += feeAmount;

        bidIdToProposalId[pool][currentBidRewardCount[pool]] = proposalId;
        currentBidRewardCount[pool] += 1;

        emit RewardDistributed(pool, proposalId, bidAmount);
    }

    /**
     * @dev get reward amount for user specified by `user`
     * @param user address of user to check balance of
     */
    function rewardBalanceOf(string calldata pool, address user)
        external
        view
        virtual
        returns (uint256 totalPendingBidReward)
    {
        UserRewardBidInfo storage rewardBidInfo = userRewardBids[pool][user];
        totalPendingBidReward = rewardBidInfo.totalPendingBidReward;

        if (_balanceOf(pool, user) > 0) {
            totalPendingBidReward += _userPendingBidRewards(
                user,
                rewardBidInfo.lastRewardBidId,
                pool
            );
        }
    }

    /**
     * @dev claimReward for msg.sender
     * @param to address to send the rewards to
     */
    function claimReward(string calldata pool, address to) external nonReentrant {
        // accrue rewards for both stkAave and Aave token balances
        _accrueRewards(pool, msg.sender);

        UserRewardBidInfo storage _currentUser = userRewardBids[pool][msg.sender];

        uint256 reward = _currentUser.totalPendingBidReward;

        if (reward > 0) {
            unchecked {
                _currentUser.totalPendingBidReward = 0;
            }

            bidAsset[pool].safeTransfer(to, reward);
        }

        emit RewardClaim(pool, msg.sender, reward, block.timestamp);
    }

    /**
     * @dev _accrueRewards accrue rewards for an address
     * @param user address to accrue rewards for
     */
    function _accrueRewards(string calldata pool, address user) internal virtual {
        require(user != address(0), "INVALID_ADDRESS");

        uint256 pendingBidReward;

        UserRewardBidInfo storage _user = userRewardBids[pool][user];

        if (_balanceOf(pool, user) > 0) {
            pendingBidReward = _userPendingBidRewards(user, _user.lastRewardBidId, pool);
            _user.totalPendingBidReward += pendingBidReward;
            _user.lastRewardBidId = currentBidRewardCount[pool];
        }

        emit RewardAccrue(pool, user, pendingBidReward, block.timestamp);
    }

    /**
     * @dev returns the user bid reward share
     * @param user user
     * @param userLastBidId user last bid id
     */
    function _userPendingBidRewards(
        address user,
        uint256 userLastBidId,
        string memory pool
    ) internal view returns (uint256 totalPendingReward) {
        uint256 _currentBidRewardCount = currentBidRewardCount[pool];

        for (uint256 i = userLastBidId; i < _currentBidRewardCount; i++) {
            uint256 proposalId = bidIdToProposalId[pool][i];
            Bid storage _bid = bids[pool][proposalId];

            uint256 amount = _getDepositAt(pool, user, _bid.proposalStartBlock);
            if (amount > 0) {
                // subtract fee from highest bid
                totalPendingReward +=
                    (amount * (_bid.bidAmount - _calculateFeeAmount(_bid.bidAmount))) /
                    _bid.totalVotes;
            }
        }
    }

    /**
     * @dev withdrawFees withdraw fees
     * Enables ONLY the fee receipient to withdraw the pool accrued fees
     */
    function withdrawFees(string calldata pool) external nonReentrant returns (uint256 feeAmount) {
        require(msg.sender == feeRecipient, "ONLY_RECEIPIENT");

        feeAmount = feesReceived[pool];

        if (feeAmount > 0) {
            feesReceived[pool] = 0;
            bidAsset[pool].safeTransfer(feeRecipient, feeAmount);
        }

        emit WithdrawFees(pool, address(this), feeAmount, block.timestamp);
    }
}
