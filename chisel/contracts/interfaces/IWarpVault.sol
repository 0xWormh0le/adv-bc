// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWarpVault {
    function balanceOf(IERC20, address) external view returns (uint256);

    function userApprovedContracts(address, address) external view returns (bool);

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256, uint256);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function toShare(
        IERC20 _token,
        uint256 _amount,
        bool _ceil
    ) external view returns (uint256);

    function toUnderlying(IERC20 token, uint256 share) external view returns (uint256);

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
