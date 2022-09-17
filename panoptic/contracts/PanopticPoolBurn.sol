// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./PanpopticPoolMint.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract PanopticPoolBurn is PanopticPoolMint {
    function burnOptions(uint256 tokenId) external {
        (, OptionEncoding.OptionConfig[] memory optionData) = OptionEncoding.decodeID(tokenId);

        sfpm.burnOptionsPosition(tokenId);
        (, int24 currentTick, , , , , ) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        uint128 numberOfOptions = uint128(
            IERC1155(address(sfpm)).balanceOf(address(this), tokenId)
        );
        for (uint256 index = 0; index < optionData.length; index++) {
            _checkLiquidityBeforeBurn(optionData[index], numberOfOptions, tickSpacing, currentTick);
        }
    }

    function _checkLiquidityBeforeBurn(
        OptionEncoding.OptionConfig memory option,
        uint128 numberOfOptions,
        int24 tickSpacing,
        int24 currentTick
    ) internal {
        (int24 tickLower, int24 tickUpper) = Utils.asTicks(
            option.strike,
            option.width,
            tickSpacing
        );

        address token = _getToken(tickLower, tickUpper, currentTick);
        bool isToken0 = token == token0;
        uint128 optionLiquidity = numberOfOptions * option.ratio;
        uint256 positionNotional = PanopticHelper.calcPositionNotional(
            optionLiquidity,
            tickLower,
            tickUpper,
            isToken0
        );
        _rebase(
            isToken0,
            currentTick,
            tickUpper,
            tickLower,
            optionLiquidity,
            option.strike,
            positionNotional
        );
    }

    function _rebase(
        bool isToken0,
        int24 currentTick,
        int24 tickUpper,
        int24 tickLower,
        uint128 optionLiquidity,
        int24 strike,
        uint256 positionNotional
    ) internal {
        if (isToken0 ? currentTick < tickUpper : currentTick > tickLower) {
            uint256 intrinsicValue = PanopticHelper.calcIntrinsicValue(
                pool,
                optionLiquidity,
                tickLower,
                tickUpper,
                strike,
                positionNotional,
                isToken0
            );
            if (isToken0) {
                totalToken0Deposited += intrinsicValue;
            } else {
                totalToken1Deposited += intrinsicValue;
            }
        }
    }
}
