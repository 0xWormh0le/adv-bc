// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./PanopticPoolBurn.sol";

abstract contract PanopticPoolHealth is PanopticPoolBurn {
    struct HealthCheckParam {
        int24 tickSpacing;
        address user;
        uint160 sqrtPriceX96;
        uint256 s;
        uint256[] positionIdList;
    }

    struct IncreamentParam {
        OptionEncoding.OptionConfig optionData;
        uint256 s;
        uint160 sqrtPriceX96;
        uint128 optionSize;
        int24 tickSpacing;
    }

    function checkHealth(address _user, uint256[] calldata _positionIdList)
        public
        view
        returns (uint256 callStatus, uint256 putStatus)
    {
        (
            uint256 callNotional,
            uint256 putNotional,
            int256 callIntrinsic,
            int256 putIntrinsic
        ) = getHealthValue(_user, _positionIdList);

        int256 token0Balance = int256(receiptToken0.balanceOf(_user));
        int256 token1Balance = int256(receiptToken1.balanceOf(_user));

        if (token0Balance < callIntrinsic + int256(callNotional * COLLATERAL_RATIO)) {
            callStatus = USER_STATUS_UNDERWATER;
        } else if (
            token0Balance <
            callIntrinsic +
                int256(
                    (callNotional * COLLATERAL_RATIO * COLLATERAL_MARGIN_RATIO) /
                        COLLATERAL_MARGIN_DECIMALS
                )
        ) {
            callStatus = USER_STATUS_MARGINCALLED;
        } else {
            callStatus = USER_STATUS_HEALTHY;
        }

        if (token1Balance < putIntrinsic + int256(putNotional * COLLATERAL_RATIO)) {
            putStatus = USER_STATUS_UNDERWATER;
        } else if (
            token1Balance <
            putIntrinsic +
                int256(
                    (putNotional * COLLATERAL_RATIO * COLLATERAL_MARGIN_RATIO) /
                        COLLATERAL_MARGIN_DECIMALS
                )
        ) {
            putStatus = USER_STATUS_MARGINCALLED;
        } else {
            putStatus = USER_STATUS_HEALTHY;
        }
    }

    function getHealthValue(address _user, uint256[] memory _positionIdList)
        public
        view
        returns (
            uint256 callNotional,
            uint256 putNotional,
            int256 callIntrinsic,
            int256 putIntrinsic
        )
    {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        HealthCheckParam memory healthCheckParam = HealthCheckParam({
            tickSpacing: pool.tickSpacing(),
            sqrtPriceX96: sqrtPriceX96,
            s: FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96) / FixedPoint96.Q96,
            positionIdList: _positionIdList,
            user: _user
        });

        return _computeHealthValue(healthCheckParam);
    }

    function _computeHealthValue(HealthCheckParam memory healthCheckParam)
        internal
        view
        returns (
            uint256 callNotional,
            uint256 putNotional,
            int256 callIntrinsic,
            int256 putIntrinsic
        )
    {
        uint256 callw;
        uint256 putw;

        for (uint256 i = 0; i < healthCheckParam.positionIdList.length; i++) {
            (, OptionEncoding.OptionConfig[] memory optionData) = OptionEncoding.decodeID(
                healthCheckParam.positionIdList[i]
            );
            uint128 optionSize = uint128(
                sfpm.balanceOf(healthCheckParam.user, healthCheckParam.positionIdList[i])
            );

            for (uint256 j = 0; j < optionData.length; j++) {
                IncreamentParam memory param = IncreamentParam({
                    s: healthCheckParam.s,
                    optionSize: optionSize,
                    optionData: optionData[j],
                    sqrtPriceX96: healthCheckParam.sqrtPriceX96,
                    tickSpacing: healthCheckParam.tickSpacing
                });

                (
                    uint256 callNotionalIncreament,
                    uint256 putNotionalIncreament,
                    uint256 callwIncreament,
                    uint256 putwIncreament
                ) = _getIncreament(param);

                if (callNotionalIncreament > 0) {
                    callNotional += callNotionalIncreament;
                }

                if (putNotionalIncreament > 0) {
                    putNotional += putNotionalIncreament;
                }

                if (callwIncreament > 0) {
                    callw += callwIncreament;
                }

                if (putwIncreament > 0) {
                    putw += putwIncreament;
                }
            }
        }

        callIntrinsic = int256((callNotional * FixedPoint96.Q96 - callw) / FixedPoint96.Q96);
        putIntrinsic = int256(putNotional) - int256(putw);
    }

    function _getIncreament(IncreamentParam memory param)
        internal
        pure
        returns (
            uint256 callNotinalIncreament,
            uint256 putNotionalIncreament,
            uint256 callwIncreament,
            uint256 putwIncreament
        )
    {
        uint128 liquidity = param.optionSize * param.optionData.ratio;
        int24 tickLower = param.optionData.strike -
            int24(param.optionData.width * param.tickSpacing);
        int24 tickUpper = param.optionData.strike +
            int24(param.optionData.width * param.tickSpacing);

        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            param.sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            liquidity
        );

        if (param.optionData.token_type == 0) {
            callNotinalIncreament = LiquidityAmounts.getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
            callwIncreament = amount0 * FixedPoint96.Q96 + (amount1 * FixedPoint96.Q96) / param.s;
        } else {
            putNotionalIncreament += LiquidityAmounts.getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
            putwIncreament = amount0 * param.s + amount1;
        }
    }
}
