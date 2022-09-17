// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "../interfaces/IOracle.sol";

contract MockPriceOracle is IOracle {
    uint256 lastestAnswer;

    constructor(uint256 _price) {
        lastestAnswer = _price;
    }

    function setPrice(uint256 _newPrice) external {
        lastestAnswer = _newPrice;
    }

    function getPriceInUSD() external view override returns (uint256) {
        return lastestAnswer;
    }

    function viewPriceInUSD() external view override returns (uint256) {
        return lastestAnswer;
    }
}
