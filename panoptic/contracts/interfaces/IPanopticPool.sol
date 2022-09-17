// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IPanopticPool {
    struct DualTokenAmountParams {
        uint256 amount0;
        uint256 amount1;
    }

    struct Collateral {
        uint256 token0;
        uint256 token1;
        uint256 notionalValue;
    }

    function startPool(address _pool, address _receiptReference) external;

    event MMDeposited(address user, address tokenAddress, uint256 amount);

    event MMWithdrawn(address user, address tokenAddress, uint256 amount);

    event FeesCollected(uint256 positionID, uint256 amount0Collected, uint256 amount1Collected);
}
