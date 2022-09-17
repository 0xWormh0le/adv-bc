// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./PanopticPoolLiquidity.sol";

import "./libraries/OptionEncoding.sol";
import "./libraries/PanopticHelper.sol";
import "./libraries/Utils.sol";

abstract contract PanopticPoolMint is PanopticPoolLiquidity {
    function mintOptions(uint256 tokenId, uint128 numberOfOptions) external {
        (, OptionEncoding.OptionConfig[] memory optionData) = OptionEncoding.decodeID(tokenId);

        (, int24 currentTick, , , , , ) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        uint256 token0Amount;
        uint256 token1Amount;
        for (uint256 index = 0; index < optionData.length; index++) {
            (bool isToken0, uint256 positionNotional) = _checkLiquidityBeforeMint(
                optionData[index],
                numberOfOptions,
                tickSpacing,
                currentTick
            );
            if (isToken0) {
                token0Amount += positionNotional;
            } else {
                token1Amount += positionNotional;
            }
        }

        _ensureLiquidity(token0, token0Amount);
        _ensureLiquidity(token1, token1Amount);

        _takeCommission(token0, token0Amount);
        _takeCommission(token1, token1Amount);

        _ensureCollateral(msg.sender, token0Amount, true);
        _ensureCollateral(msg.sender, token1Amount, false);

        _updateCollateral(msg.sender, token0Amount, true, true);
        _updateCollateral(msg.sender, token1Amount, true, false);

        sfpm.mintOptionsPosition(tokenId, numberOfOptions, address(this), pool);
    }

    function _checkLiquidityBeforeMint(
        OptionEncoding.OptionConfig memory option,
        uint128 numberOfOptions,
        int24 tickSpacing,
        int24 currentTick
    ) internal view returns (bool isToken0, uint256 positionNotional) {
        (int24 tickLower, int24 tickUpper) = Utils.asTicks(
            option.strike,
            option.width,
            tickSpacing
        );

        address token = _getToken(tickLower, tickUpper, currentTick);
        isToken0 = token == token0;
        uint128 optionLiquidity = numberOfOptions * option.ratio;
        positionNotional = PanopticHelper.calcPositionNotional(
            optionLiquidity,
            tickLower,
            tickUpper,
            isToken0
        );
    }

    function _ensureLiquidity(address token, uint256 amount) internal view {
        require(IERC20(token).balanceOf(address(this)) >= amount, "7");
    }

    function _getToken(
        int24 tickLower,
        int24 tickUpper,
        int24 currentTick
    ) internal view returns (address token) {
        if (currentTick > tickUpper) {
            token = token1;
        } else if (currentTick < tickLower) {
            token = token0;
        }
    }

    function _takeCommission(address token, uint256 positionNotional) internal {
        if (positionNotional == 0) {
            return;
        }

        uint256 commission = (positionNotional * COMMISSION_FEE) / DECIMALS;
        if (token == token0) {
            totalToken0Deposited += commission;
        } else if (token == token1) {
            totalToken1Deposited += commission;
        }
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), commission);
    }

    function _ensureCollateral(
        address owner,
        uint256 positionNotional,
        bool isToken0
    ) internal view {
        uint256 required = (positionNotional * SELL_COLLATERAL_RATIO) / DECIMALS;
        uint256 deposits = IERC20(isToken0 ? receiptToken0 : receiptToken1).balanceOf(owner);
        uint256 locked = isToken0 ? collaterals[owner].token0 : collaterals[owner].token1;

        require(required <= deposits + locked, "6");
    }

    function _updateCollateral(
        address owner,
        uint256 positionNotional,
        bool increase,
        bool isToken0
    ) internal {
        Collateral storage collateral = collaterals[owner];

        if (increase) {
            collateral.notionalValue += positionNotional;
        } else {
            collateral.notionalValue -= positionNotional;
        }

        uint256 locked = (positionNotional * SELL_COLLATERAL_RATIO) / DECIMALS;

        if (isToken0) {
            if (increase) {
                collateral.token0 += locked;
            } else {
                collateral.token0 -= locked;
            }
        } else {
            if (increase) {
                collateral.token1 += locked;
            } else {
                collateral.token1 -= locked;
            }
        }
    }
}
