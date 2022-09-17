//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../pool/PoolBase.sol";
import "./CompoundAsset.sol";
import "./CompoundVote.sol";

contract CompoundPool is PoolBase {
    /**
     * @dev constructor
     * @param governanceToken_ Comp governance token address
     * @param bidAsset_ bid asset
     * @param bribeRewardGauge_ bribe reward gauge contract address
     * @param governanceContract_ governance contract
     * @param rootTunnel_ root tunnel contract address
     */
    constructor(
        address governanceToken_,
        address bidAsset_,
        address bribeRewardGauge_,
        address governanceContract_,
        address rootTunnel_
    )
        Ownable()
        Pausable()
        ReentrancyGuard()
        PoolStorage(
            "comp",
            bidAsset_,
            rootTunnel_,
            address(
                new CompoundAsset(
                    governanceToken_,
                    bribeRewardGauge_,
                    address(new CompoundVote(address(this), governanceContract_))
                )
            )
        )
    {}

    /**
     * @dev get proposal state
     * @param proposalId proposal id
     */
    function _getProposalState(uint256 proposalId) internal view override returns (ProposalState) {
        IGovernorBravo.ProposalState state = IGovernorBravo(
            IVote(asset.voteContract()).governanceContract()
        ).state(proposalId);

        if (uint256(state) == uint256(ProposalState.Active)) {
            return ProposalState.Active;
        } else if (uint256(state) == uint256(ProposalState.Canceled)) {
            return ProposalState.Canceled;
        } else {
            return ProposalState(uint256(state));
        }
    }

    /**
     * @dev get propsoal detail by id
     * @param proposalId proposal id
     */
    function _getProposalById(uint256 proposalId) internal view override returns (Proposal memory) {
        IGovernorBravo.Proposal memory proposal = IGovernorBravo(
            IVote(asset.voteContract()).governanceContract()
        ).proposals(proposalId);
        return Proposal(proposal.startBlock, proposal.endBlock);
    }
}
