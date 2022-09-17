// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "../interfaces/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "../PanopticFactory.sol";
import {PanopticPool} from "../PanopticPool.sol";

contract User {
    ISwapRouter public constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    uint24 public constant fee = 3000;

    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) public {
        TransferHelper.safeApprove(token, spender, amount);
    }

    function getPool() public pure returns (IUniswapV3Pool) {
        return
            IUniswapV3Pool(
                PoolAddress.computeAddress(
                    factory,
                    PoolAddress.getPoolKey(WETH_ADDRESS, USDC_ADDRESS, fee)
                )
            );
    }

    function swapWethForUsdc(uint256 amountIn) public returns (uint256 amountOut) {
        approveToken(WETH_ADDRESS, address(router), amountIn);
        amountOut = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH_ADDRESS,
                tokenOut: USDC_ADDRESS,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 1000,
                amountIn: amountIn,
                amountOutMinimum: 1,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function swapUsdcForWETH(uint256 amountIn) public returns (uint256 amountOut) {
        approveToken(USDC_ADDRESS, address(router), amountIn);
        amountOut = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: USDC_ADDRESS,
                tokenOut: WETH_ADDRESS,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 1000,
                amountIn: amountIn,
                amountOutMinimum: 1,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function createPool(
        PanopticFactoryV2 _factory,
        address token0,
        address token1,
        uint24 _fee
    ) public returns (address) {
        return _factory.createPool(token0, token1, _fee);
    }

    function MMDeposit(
        PanopticPool pool,
        PanopticPool.DualTokenAmountParams calldata params,
        address to
    ) public {
        pool.MMdeposit(params, to);
    }

    function MMWithdraw(PanopticPool pool, PanopticPool.DualTokenAmountParams calldata params)
        public
    {
        pool.MMwithdraw(params);
    }

    function MintOptions(
        PanopticPool pool,
        uint256 tokenId,
        uint128 numberOfOptions
    ) public {
        pool.mintOptions(tokenId, numberOfOptions);
    }
}
