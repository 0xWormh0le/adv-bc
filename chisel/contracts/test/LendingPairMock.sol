//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IWarpVault.sol';
import '../external/library/DataTypes.sol';

contract LendingPairMock {
    IERC20 public asset;

    IWarpVault public vault;

    function depositBorrowAsset(address _tokenRecipient, uint256 _amount) external {
        uint256 vaultShareAmount = vault.toShare(asset, _amount, false);
        // requirement: vault's approveContract required - msg.sender approves lending pair
        vault.transfer(asset, msg.sender, address(this), vaultShareAmount);
    }

    function redeem(address _to, uint256 _amount) external {
        uint256 vaultShareAmount = vault.toShare(asset, _amount, false);
        vault.transfer(asset, address(this), _to, vaultShareAmount);
    }

    function mockInitialize(IERC20 _asset, IWarpVault _vault) external {
        asset = _asset;
        vault = _vault;
    }

    function exchangeRateCurrent() external pure returns (uint256) {
        return 1100000000000000000;
    }
}
