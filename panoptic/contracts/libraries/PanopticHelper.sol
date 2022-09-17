// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

library PanopticHelper {
    function calcPositionNotional(
        uint128 optionSize,
        int24 tickLower,
        int24 tickUpper,
        bool isToken0
    ) public pure returns (uint256) {
        return
            isToken0
                ? SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    optionSize,
                    true
                )
                : SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    optionSize,
                    true
                );
    }

    function calcIntrinsicValue(
        IUniswapV3Pool _pool,
        uint128 optionSize,
        int24 tickLower,
        int24 tickUpper,
        int24 strike,
        uint256 positionNotional,
        bool
    ) public view returns (uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = _pool.slot0();

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            optionSize
        );

        return
            positionNotional -
            amount0 -
            FullMath.mulDiv(amount1, TickMath.getSqrtRatioAtTick(2 * strike), FixedPoint96.Q96);
    }
}
