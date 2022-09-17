//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IRootTunnel.sol";
import "../interfaces/IVote.sol";
import "./PoolAdmin.sol";

abstract contract PoolBase is IPool, ReentrancyGuard, PoolAdmin {
    using SafeERC20 for IERC20;

    bytes32 public constant BID_INFO = keccak256("BID_INFO");

    function vote(uint256 proposalId) external nonReentrant {
        Bid storage currentBid = bids[proposalId];
        bool support = currentBid.yesBid >= currentBid.noBid;

        require(currentBid.endBlock > 0, "INVALID_PROPOSAL");
        require(currentBid.endBlock < block.number, "BID_ACTIVE");

        if (currentBid.voted || currentBid.yesBid + currentBid.noBid == 0) {
            return;
        }

        currentBid.voted = true;

        uint256 bidAmount = currentBid.yesBid + currentBid.noBid;

        bidAsset.safeApprove(address(rootTunnel), bidAmount);
        rootTunnel.deposit(
            address(bidAsset),
            address(0), // meaningless as token will be minted to child tunnel itself
            bidAmount,
            ""
        );

        rootTunnel.sendBidInfo(
            name,
            bidAmount,
            currentBid.proposalStartBlock,
            currentBid.totalVotes,
            proposalId
        );

        IVote(asset.voteContract()).vote(proposalId, support);

        emit Vote(proposalId, msg.sender, support, block.timestamp);
    }

    /**
     * @dev place a bid after check AaveGovernance status
     * @param proposalId proposal id
     * @param amount amount of bid assets
     * @param support the suport for the proposal
     */
    function bid(
        uint256 proposalId,
        uint128 amount,
        bool support
    ) external whenNotPaused nonReentrant {
        ProposalState state = _getProposalState(proposalId);
        Bid storage currentBid = bids[proposalId];

        require(
            state == ProposalState.Pending || state == ProposalState.Active,
            "INVALID_PROPOSAL_STATE"
        );
        require(blockedProposals[proposalId] == false, "PROPOSAL_BLOCKED");
        require(!userBids[msg.sender][proposalId], "USER_ALREADY_BID");

        // new bid
        if (currentBid.proposalStartBlock == 0) {
            Proposal memory proposal = _getProposalById(proposalId);
            currentBid.endBlock = proposal.endBlock - endBidFromProposal;
            currentBid.proposalStartBlock = proposal.startBlock;
            currentBid.totalVotes = IVote(asset.voteContract()).votingPower(proposal);
        }

        require(currentBid.endBlock > block.number, "BID_ENDED");
        require(currentBid.totalVotes > 0, "INVALID_VOTING_POWER");

        bidAsset.safeTransferFrom(msg.sender, address(this), amount);

        if (support) {
            currentBid.yesBid += amount;
        } else {
            currentBid.noBid += amount;
        }

        // write the new bid info to storage
        userBids[msg.sender][proposalId] = true;

        emit BidMade(proposalId, msg.sender, amount, support);
    }

    /**
     * @dev refund bid for a cancelled proposal ONLY if it was not voted on
     * @param proposalId proposal id
     * @param amount bid amount that will be refunded
     * @param proof merkle nodes
     */
    function refund(
        uint256 proposalId,
        uint128 amount,
        bytes32[] calldata proof
    ) external nonReentrant {
        Bid storage currentBid = bids[proposalId];

        require(currentBid.merkleProof != bytes32(0), "NO_MERKLE_PROOF");
        require(
            MerkleProof.verify(
                proof,
                currentBid.merkleProof,
                keccak256(abi.encodePacked(msg.sender, amount))
            ),
            "AMOUNT_NOT_VERIFIED"
        );

        // refund the bid money
        bidAsset.safeTransfer(msg.sender, amount);

        emit Refund(proposalId, msg.sender, amount);
    }
}
