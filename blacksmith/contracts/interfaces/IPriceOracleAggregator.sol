// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOracle.sol";

interface IPriceOracleAggregator {
    event UpdateOracle(IERC20 token, IOracle oracle);

    function getPriceInUSD(IERC20 _token) external returns (uint256);

    function updateOracleForAsset(IERC20 _asset, IOracle _oracle) external;

    function viewPriceInUSD(IERC20 _token) external view returns (uint256);
}
