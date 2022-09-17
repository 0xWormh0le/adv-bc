//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../external/library/DataTypes.sol';

interface IWarpLendingPair {
    function asset() external view returns (IERC20);

    function depositBorrowAsset(address _tokenReceipeint, uint256 _amount) external;

    function redeem(address _to, uint256 _amount) external;

    function exchangeRateCurrent() external returns (uint256);
}
