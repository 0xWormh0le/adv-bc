//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IVote.sol";

abstract contract Vote is IVote {
    address public immutable pool;
    address public immutable override governanceContract;

    constructor(address pool_, address governanceContract_) {
        pool = pool_;
        governanceContract = governanceContract_;
    }

    function vote(uint256 proposalId, bool support) external override {
        require(msg.sender == pool, "Vote: only pool");
        _vote(proposalId, support);
    }

    function _vote(uint256 proposalId, bool support) internal virtual;
}
