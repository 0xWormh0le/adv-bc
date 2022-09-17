//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IBribeRewardGauge {
    function accrueRewards(address user) external;
}
