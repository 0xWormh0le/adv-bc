// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import "@openzeppelin/contracts/proxy/BeaconProxy.sol";
import "./interfaces/IPanopticPool.sol";

contract PanopticFactoryV2 is Ownable, ReentrancyGuard {
    event PoolDeployed(address poolAddress, address uniSwapPool);

    // implementation address
    address public immutable panpoolBeacon;
    // implementation address
    address public immutable receiptToken;

    address public immutable uniswapV3Factory;

    mapping(address => address) public uniswapPoolToPanpool;

    constructor(
        address _panpoolBeacon,
        address _owner,
        address _receiptToken,
        address _uniswapV3Factory
    ) Ownable() {
        transferOwnership(_owner);
        panpoolBeacon = _panpoolBeacon;
        receiptToken = _receiptToken;
        uniswapV3Factory = _uniswapV3Factory;
    }

    function createPool(
        address token0,
        address token1,
        uint24 fee
    ) external onlyOwner returns (address) {
        address uniswapPool = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, fee);

        require(uniswapPool != address(0), "Pool Should exists");
        require(uniswapPoolToPanpool[uniswapPool] == address(0), "Already Created");

        bytes memory empty;
        address panPoolProxy = address(new BeaconProxy(panpoolBeacon, empty));
        IPanopticPool panpool = IPanopticPool(panPoolProxy);

        uniswapPoolToPanpool[uniswapPool] = panPoolProxy;
        panpool.startPool(uniswapPool, receiptToken);

        return address(panpool);
    }

    function getPanPoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (address) {
        address uniswapPool = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, fee);
        return uniswapPoolToPanpool[uniswapPool];
    }
}
