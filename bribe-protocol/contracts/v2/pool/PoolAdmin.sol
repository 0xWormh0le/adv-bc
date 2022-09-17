//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./PoolStorage.sol";

abstract contract PoolAdmin is PoolStorage, Pausable, Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev set end bid from proposal
     * @param value value
     */
    function setEndBidFromProposal(uint256 value) external onlyOwner {
        endBidFromProposal = value;

        emit SetEndBidFromProposal(msg.sender);
    }

    /**
     * @dev submit merkle root proving bidders' amount for cancelled proposal
     * @param proposalId proposal id
     * @param proof merkle proof of user bid amounts
     */
    function submitRefundProof(uint256 proposalId, bytes32 proof) external onlyOwner {
        Bid storage currentBid = bids[proposalId];

        require(_getProposalState(proposalId) == ProposalState.Canceled, "PROPOSAL_ACTIVE");
        require(!currentBid.voted, "BID_DISTRIBUTED");

        currentBid.merkleProof = proof;
    }

    /**
     * @dev block a proposalId from used in the pool
     * @param proposalId proposalId
     * @param proof merkle proof of user bid amounts
     */
    function blockProposalId(uint256 proposalId, bytes32 proof) external onlyOwner {
        Bid storage currentBid = bids[proposalId];

        require(blockedProposals[proposalId] == false, "PROPOSAL_INACTIVE");
        require(!currentBid.voted, "BID_DISTRIBUTED");

        currentBid.merkleProof = proof;
        blockedProposals[proposalId] = true;

        emit BlockProposalId(proposalId, block.timestamp);
    }

    /**
     * @notice pause pool actions
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpause pool actions
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice setFeeRecipient
     * @param newRecipient new fee receipeitn
     */
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "INVALID_RECIPIENT");

        // todo: feeRecipient = newRecipient;

        emit UpdateFeeRecipient(address(this), newRecipient);
    }

    /*****************************************
     *            Virtual functions
     ******************************************/

    /**
     * @dev get proposal state
     * @param proposalId proposal id
     */
    function _getProposalState(uint256 proposalId) internal view virtual returns (ProposalState) {}

    /**
     * @dev get propsoal detail by id
     * @param proposalId proposal id
     */
    function _getProposalById(uint256 proposalId) internal view virtual returns (Proposal memory) {}
}
