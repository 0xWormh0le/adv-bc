//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/Compound/IGovernorBravo.sol";
import "../interfaces/Compound/IComp.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/IPool.sol";
import "../Vote.sol";

contract CompoundVote is Vote {
    constructor(address pool, address governanceContract) Vote(pool, governanceContract) {}

    /**
     * @dev vote to `proposalId` with `support` option
     * @param proposalId proposal id
     */
    function _vote(uint256 proposalId, bool support) internal override {
        IGovernorBravo(governanceContract).castVote(proposalId, support);
    }

    /**
     * @dev returns the pool voting power for a proposal
     * @param proposal proposal to fetch pool voting power
     */
    function votingPower(IPool.Proposal calldata proposal)
        external
        view
        override
        returns (uint256 power)
    {
        power = IComp(address(IPool(pool).asset().governanceToken())).getPriorVotes(
            address(this),
            proposal.startBlock
        );
    }
}
