//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAsset.sol";
import "./IRootTunnel.sol";

interface IPool {
    enum ProposalState {
        Pending,
        Canceled,
        Active,
        Failed,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    enum UserBidOption {
        None,
        Yes,
        No
    }

    struct Proposal {
        uint256 startBlock;
        uint256 endBlock;
    }

    /// @dev proposal bid info
    struct Bid {
        uint256 totalVotes;
        uint256 proposalStartBlock;
        uint256 endBlock;
        uint128 yesBid;
        uint128 noBid;
        /// @dev merkle proof of user bid amounts
        bytes32 merkleProof;
        bool voted;
    }

    /***************************
        events
     ***************************/

    event Vote(uint256 indexed proposalId, address user, bool support, uint256 timestamp);

    event BidMade(uint256 indexed proposalId, address sender, uint128 amount, bool support);

    event Refund(uint256 indexed proposalId, address bidder, uint256 bidAmount);

    event UpdateFeeRecipient(address sender, address receipient);

    event BlockProposalId(uint256 indexed proposalId, uint256 timestamp);

    event SetEndBidFromProposal(address indexed user);

    /***************************
        functions
     ***************************/

    function name() external view returns (string memory);

    function asset() external view returns (IAsset);

    function rootTunnel() external view returns (IRootTunnel);
}
