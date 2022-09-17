// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;
pragma abicoder v2;

library Utils {
    function asTicks(
        int24 strike,
        int24 width,
        int24 tickSpacing
    ) internal pure returns (int24 tickLower, int24 tickUpper) {
        int24 range = width * tickSpacing;
        (tickLower, tickUpper) = (strike - range, strike + range);
    }
}
