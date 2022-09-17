//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/Compound/IGovernorBravo.sol";
import "../interfaces/Compound/IComp.sol";
import "../Asset.sol";

contract CompoundAsset is Asset {
    /**
     * @dev constructor
     * @param governanceToken_ governance token address
     * @param bribeRewardGauge_ reward gauge contract address
     * @param voteContract_ vote contract address
     */
    constructor(
        address governanceToken_,
        address bribeRewardGauge_,
        address voteContract_
    )
        Asset(
            governanceToken_,
            bribeRewardGauge_,
            msg.sender, // pool contract
            voteContract_
        )
    {}

    /**
     * @dev delegates voting power to vote contract
     */
    function _delegate() internal override {
        IComp(address(governanceToken)).delegate(voteContract);
    }
}
