//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../interfaces/IWarpVault.sol';

contract VaultMock is IWarpVault {
    using SafeERC20 for IERC20;

    struct TotalBase {
        uint256 totalUnderlyingDeposit; // total underlying asset deposit
        uint256 totalSharesMinted; // total vault shares minted
    }

    constructor() {}

    mapping(IERC20 => mapping(address => uint256)) public override balanceOf;

    mapping(address => mapping(address => bool)) public override userApprovedContracts;

    mapping(IERC20 => TotalBase) public totals;

    address public owner;

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external override returns (uint256 amountOut, uint256 shareOut) {
        // calculate shares
        amountOut = _amount;
        shareOut = toShare(_token, _amount, false);

        // transfer appropriate amount of underlying from _from to vault
        _token.safeTransferFrom(_from, address(this), _amount);

        balanceOf[_token][_to] = balanceOf[_token][_to] + shareOut;

        TotalBase storage total = totals[_token];
        total.totalUnderlyingDeposit += _amount;
        total.totalSharesMinted += shareOut;
    }

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external override returns (uint256 amountOut) {
        amountOut = toUnderlying(_token, _shares);
        balanceOf[_token][_from] = balanceOf[_token][_from] - _shares;

        TotalBase storage total = totals[_token];

        total.totalUnderlyingDeposit -= amountOut;
        total.totalSharesMinted -= _shares;

        _token.safeTransfer(_to, amountOut);
    }

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external override {
        balanceOf[_token][_from] -= _shares;
        balanceOf[_token][_to] += _shares;
    }

    function toShare(
        IERC20 _token,
        uint256 _amount,
        bool _ceil
    ) public view override returns (uint256 share) {
        TotalBase storage total = totals[_token];

        uint256 currentTotal = total.totalSharesMinted;
        if (currentTotal > 0) {
            uint256 currentUnderlyingBalance = total.totalUnderlyingDeposit;
            share = (_amount * currentTotal) / currentUnderlyingBalance;

            if (_ceil && ((share * currentUnderlyingBalance) / currentTotal) < _amount) {
                share = share + 1;
            }
        } else {
            share = _amount;
        }
    }

    function toUnderlying(IERC20 _token, uint256 _share)
        public
        view
        override
        returns (uint256 amount)
    {
        TotalBase storage total = totals[_token];
        amount = (_share * total.totalUnderlyingDeposit) / total.totalSharesMinted;
    }

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {}

    function allowContract(address _contract, bool _status) external {}
}
