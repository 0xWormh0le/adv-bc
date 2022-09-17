// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";

import "./interfaces/IPanopticPool.sol";
import "./interfaces/ISemiFungiblePositionManager.sol";
import "./ReceiptBase.sol";

// import "hardhat/console.sol";

abstract contract PanopticPoolLiquidity is IPanopticPool, Ownable, ReentrancyGuard {
    IUniswapV3Pool public pool;
    ISemiFungiblePositionManager public immutable sfpm;

    address public token0;
    address public token1;

    ReceiptBase public receiptToken0;
    ReceiptBase public receiptToken1;

    mapping(address => uint256[]) public optionsOfOwner;
    mapping(uint256 => uint256) public indexOfOptionInOwnerArray;

    mapping(address => Collateral) public collaterals;

    uint256 public constant TICK_SCALE = 2**96;

    uint256 public constant DECIMALS = 1000;
    uint256 public constant USER_STATUS_UNDERWATER = 0;
    uint256 public constant USER_STATUS_MARGINCALLED = 1;
    uint256 public constant USER_STATUS_HEALTHY = 2;

    /// @dev THIS RATIO IS 1, SINCE RATIO/DECIMALS = 1. IF WE WANT RATIO 0.8, THEN WE CHANGE IT TO 800
    uint256 public constant COLLATERAL_RATIO = 2000;
    uint256 public constant SELL_COLLATERAL_RATIO = 200;
    uint256 public constant BUY_COLLATERAL_RATIO = 150;
    /// @dev THIS MARGIN IS 1.2, SINCE RATIO/DECIMALS = 1. IF WE WANT RATIO 0.8, THEN WE CHANGE IT TO 800
    uint256 public constant COLLATERAL_MARGIN_RATIO = 1200;
    uint256 public constant COLLATERAL_MARGIN_DECIMALS = 1000;
    uint256 public constant COMMISSION_FEE = 1;

    uint256 public totalToken0Deposited;
    uint256 public totalToken1Deposited;

    constructor(address _sfpm) {
        sfpm = ISemiFungiblePositionManager(_sfpm);
    }

    function startPool(address _pool, address _receiptReference) external override {
        require(address(pool) == address(0), "10");
        require(_pool != address(0), "11");

        pool = IUniswapV3Pool(_pool);

        token0 = pool.token0();
        token1 = pool.token1();

        receiptToken0 = ReceiptBase(Clones.clone(_receiptReference));
        receiptToken0.startToken(token0);

        receiptToken1 = ReceiptBase(Clones.clone(_receiptReference));
        receiptToken1.startToken(token1);

        IERC20(token0).approve(address(pool), type(uint256).max);
        IERC20(token1).approve(address(pool), type(uint256).max);

        IERC20(token0).approve(address(sfpm), type(uint256).max);
        IERC20(token1).approve(address(sfpm), type(uint256).max);
    }

    function MMdeposit(DualTokenAmountParams calldata params, address to) external {
        require(params.amount0 > 0 || params.amount1 > 0, "9");

        if (params.amount0 > 0) {
            TransferHelper.safeTransferFrom(token0, msg.sender, address(this), params.amount0);
            uint256 toMint = _tokensToMintOrBurn(true, params.amount0);
            totalToken0Deposited += params.amount0;
            receiptToken0.mint(to, toMint);
            emit MMDeposited(to, token0, params.amount0);
        }

        if (params.amount1 > 0) {
            TransferHelper.safeTransferFrom(token1, msg.sender, address(this), params.amount1);
            uint256 toMint = _tokensToMintOrBurn(false, params.amount1);
            totalToken1Deposited += params.amount1;
            receiptToken1.mint(to, toMint);
            emit MMDeposited(to, token1, params.amount1);
        }
    }

    // amount here are actual amounts, not receipt tokens
    function MMwithdraw(DualTokenAmountParams calldata params) external {
        require(params.amount0 > 0 || params.amount1 > 0, "8");

        if (params.amount0 > 0) {
            uint256 toBurn = _tokensToMintOrBurn(true, params.amount0);
            require(params.amount0 <= getUnlockedAmount(msg.sender, true), "19");
            receiptToken0.burn(msg.sender, toBurn);
            totalToken0Deposited -= params.amount0;
            TransferHelper.safeTransfer(token0, msg.sender, params.amount0);
            emit MMWithdrawn(msg.sender, token0, params.amount0);
        }

        if (params.amount1 > 0) {
            uint256 toBurn = _tokensToMintOrBurn(false, params.amount1);
            require(params.amount1 <= getUnlockedAmount(msg.sender, false), "19");
            receiptToken1.burn(msg.sender, toBurn);
            totalToken1Deposited -= params.amount1;
            TransferHelper.safeTransfer(token1, msg.sender, params.amount1);
            emit MMWithdrawn(msg.sender, token1, params.amount1);
        }
    }

    function MMwithdrawUsingReceiptTokens(DualTokenAmountParams calldata burnParams) external {
        require(burnParams.amount0 > 0 || burnParams.amount1 > 0, "8");

        if (burnParams.amount0 > 0) {
            uint256 _toSend = _receiptTokenToAmount(true, burnParams.amount0);
            require(_toSend <= getUnlockedAmount(msg.sender, true), "19");
            receiptToken0.burn(msg.sender, burnParams.amount0);
            totalToken0Deposited -= _toSend;
            TransferHelper.safeTransfer(token0, msg.sender, _toSend);
            emit MMWithdrawn(msg.sender, token0, _toSend);
        }

        if (burnParams.amount1 > 0) {
            uint256 _toSend = _receiptTokenToAmount(false, burnParams.amount1);
            require(_toSend <= getUnlockedAmount(msg.sender, false), "19");
            receiptToken1.burn(msg.sender, _toSend);
            totalToken1Deposited -= _toSend;
            TransferHelper.safeTransfer(token1, msg.sender, _toSend);
            emit MMWithdrawn(msg.sender, token1, _toSend);
        }
    }

    function _tokensToMintOrBurn(bool isToken0, uint256 amount) internal view returns (uint256) {
        address token = isToken0 ? address(receiptToken0) : address(receiptToken1);
        uint256 totalSupply = IERC20(token).totalSupply();
        uint256 tokensDeposit = isToken0 ? totalToken0Deposited : totalToken1Deposited;
        if (tokensDeposit == 0) {
            return amount;
        } else {
            return (amount * totalSupply) / tokensDeposit;
        }
    }

    function _receiptTokenToAmount(bool isToken0, uint256 amount) internal view returns (uint256) {
        address token = isToken0 ? address(receiptToken0) : address(receiptToken1);
        uint256 totalSupply = IERC20(token).totalSupply();
        if (totalSupply != 0) {
            uint256 tokensDeposit = isToken0 ? totalToken0Deposited : totalToken1Deposited;
            return (amount * tokensDeposit) / totalSupply;
        } else {
            return amount;
        }
    }

    function getUnlockedAmount(address user, bool isToken0) public view returns (uint256) {
        address token = isToken0 ? address(receiptToken0) : address(receiptToken1);
        uint256 rtBalance = IERC20(token).balanceOf(user);
        uint256 underlyingAmount = _receiptTokenToAmount(isToken0, rtBalance);
        return underlyingAmount - (isToken0 ? collaterals[user].token0 : collaterals[user].token1);
    }
}
