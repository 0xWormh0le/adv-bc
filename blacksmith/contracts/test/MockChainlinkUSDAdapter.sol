// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/IOracle.sol";

contract MockChainlinkUSDAdapter is IOracle {
    function getPriceInUSD() external pure override returns (uint256 price) {
        return 1e8;
    }

    function viewPriceInUSD() external pure override returns (uint256 price) {
        return 1e8;
    }
}
