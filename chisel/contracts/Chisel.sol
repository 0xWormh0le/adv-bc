//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import 'hardhat/console.sol';
import './interfaces/IWarpVault.sol';
import './external/token/ERC20.sol';
import './ChiselInterest.sol';

//////////////////////////////////////////
/// @title Chisel
/// @notice Chisel manages liquidity of ledingPairs
//////////////////////////////////////////
contract Chisel is ChiselInterest {
    /// @notice Deposit with tokens
    /// requirement: depositer needs to approve chisel in Vault
    /// @param _amount amount of deposit token
    /// @param _isVaultShare deposit with vaultShares or not
    function deposit(uint256 _amount, bool _isVaultShare) external override {
        require(_amount > 0, 'deposit: Invalid Amount');

        uint256 vaultShares;
        if (_isVaultShare) {
            vaultShares = _amount;
            vault.transfer(baseToken, msg.sender, address(this), vaultShares);
        } else {
            (, vaultShares) = vault.deposit(baseToken, msg.sender, address(this), _amount);
        }
        bufferVaultShares += vaultShares;

        claim(msg.sender);
        _mint(msg.sender, _amount);
        emit Deposited(msg.sender, vaultShares, _isVaultShare);
    }

    /// @notice Withdraw user funds
    /// @param _pair lending pair from where funds will be withdrawn from
    /// @param _amount withdraw amount
    /// @param _recipient withdraw to
    function withdraw(
        IWarpLendingPair _pair,
        uint256 _amount,
        address _recipient
    ) external override matchingPair(_pair) nonReentrant {
        uint256 receiptTokenBalance = balanceOf(msg.sender);
        uint256 withdrawAmount = _amount > 0 ? _amount : receiptTokenBalance;

        require(receiptTokenBalance >= withdrawAmount, 'withdraw: Exceed');

        claim(msg.sender);
        _burn(msg.sender, withdrawAmount);

        uint256 withdrawVaultShare = vault.toShare(baseToken, withdrawAmount, true);
        if (withdrawVaultShare <= bufferVaultShares) {
            // withdraw from Chisel itself
            bufferVaultShares -= withdrawVaultShare;
        } else {
            // redeem lacking amount from _pair
            uint256 lackingVaultShares = withdrawVaultShare - bufferVaultShares;
            require(
                pairVaultShares[_pair] >= lackingVaultShares,
                'withdraw: Not Enough Pool Balance'
            );
            pairVaultShares[_pair] -= lackingVaultShares;

            _pair.redeem(address(this), lackingVaultShares);
            bufferVaultShares = 0;
        }

        vault.withdraw(baseToken, address(this), _recipient, withdrawVaultShare);
        emit Withdraw(_pair, withdrawVaultShare, _recipient);
    }

    /// @notice add Chisel funds into lendingPair
    /// @param _pair lendingPair that funds will be deposited into
    /// @param _vaultShares vault share of token amounts to be added to the pair
    function addLiquidityToPair(IWarpLendingPair _pair, uint256 _vaultShares)
        external
        override
        onlyAdmin
        matchingPair(_pair)
    {
        require(bufferVaultShares >= _vaultShares, 'addLiquidityToPair: Exceeds bufferVaultShares');
        bufferVaultShares -= _vaultShares;

        // requirement: vault's approveContract required - chisel approves lending pair
        _addLiquidityToPair(_pair, _vaultShares);

        pairVaultShares[_pair] += _vaultShares;
        emit LiquidityAdded(_pair, _vaultShares);
    }

    /// @notice collect pairIncome (all interests) earned from lendingPair and add to distribute
    /// @dev originalPairIncome = exchangeRate * principal - principal
    /// redeemAmount = originalPairIncome / exchangeRate;
    /// @param _pair lendingPair where income will be collected from
    function distributeIncome(IWarpLendingPair _pair) public nonReentrant matchingPair(_pair) {
        require(pairVaultShares[_pair] > 0, 'distributeIncome: Not deposited yet');

        uint256 exchangeRateMantissa = _pair.exchangeRateCurrent();
        require(exchangeRateMantissa >= 1e18, 'distributeIncome: no interests');

        uint256 originalPairIncome = (exchangeRateMantissa * pairVaultShares[_pair]) /
            1e18 -
            pairVaultShares[_pair];
        uint256 redeemAmount = (originalPairIncome * 1e18) / exchangeRateMantissa;

        _pair.redeem(address(this), redeemAmount);

        // reward callerReward to the caller
        uint256 callerReward = (redeemAmount * callIncentive) / 10000;
        vault.withdraw(baseToken, address(this), msg.sender, callerReward);

        // distribute remaining
        uint256 netIncome = redeemAmount - callerReward;
        addIncome(netIncome);

        emit FeeDistribution(redeemAmount, netIncome);
    }

    /// @notice move liquidity from one lendingPair to another
    /// @param _from pair that funds are withdraw
    /// @param _to target pair
    /// @param _vaultShares vault share of move amount
    function rebalance(
        IWarpLendingPair _from,
        IWarpLendingPair _to,
        uint256 _vaultShares
    ) external onlyAdmin matchingPair(_from) matchingPair(_to) {
        require(
            pairVaultShares[_from] >= _vaultShares,
            'rebalance: exceeds Chisel deposited funds'
        );

        _from.redeem(address(this), _vaultShares); // withraw liquidty
        pairVaultShares[_from] -= _vaultShares;

        pairVaultShares[_to] += _vaultShares;
        _addLiquidityToPair(_to, _vaultShares); // add liquidity

        emit Rebalance(_from, _to, _vaultShares);
    }
}
