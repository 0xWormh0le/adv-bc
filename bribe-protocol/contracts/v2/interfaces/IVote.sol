//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IPool.sol";

interface IVote {
    function vote(uint256 proposalId, bool support) external;

    function votingPower(IPool.Proposal calldata proposal) external view returns (uint256 power);

    function governanceContract() external view returns (address);
}
