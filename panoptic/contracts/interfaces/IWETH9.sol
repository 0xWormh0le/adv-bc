// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}
