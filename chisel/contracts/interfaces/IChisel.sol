//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import './IWarpLendingPair.sol';

interface IChisel {
    /////////////////////////
    // Events
    /////////////////////////
    event Initialized(address _admin, address _vault, address _baseToken);
    event Deposited(address _depositor, uint256 _vaultShares, bool _isVaultShare);
    event Withdraw(IWarpLendingPair _pair, uint256 _vaultShares, address _recipient);
    event LiquidityAdded(IWarpLendingPair _pair, uint256 _amount);

    event Claim(address indexed account, uint256 amount);
    event NewIncome(uint256 addAmount, uint256 rewardRate);
    event FeeDistribution(uint256 income, uint256 amount);
    event NewCallIncentiveSet(uint256 value);
    event IncentiveCallerSet(address account, bool isIncentive);
    event Rebalance(IWarpLendingPair _from, IWarpLendingPair _to, uint256 _vaultShares);

    /////////////////////////
    // Functions
    /////////////////////////
    function initialize(
        address _admin,
        address _vault,
        address _baseToken
    ) external;

    function deposit(uint256 _amount, bool _isVaultShare) external;

    function withdraw(
        IWarpLendingPair _pair,
        uint256 _amount,
        address _recipient
    ) external;

    function addLiquidityToPair(IWarpLendingPair _pair, uint256 _vaultShares) external;
}
