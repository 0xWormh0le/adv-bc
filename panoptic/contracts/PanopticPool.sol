// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./PanopticPoolHealth.sol";

contract PanopticPool is PanopticPoolHealth {
    constructor(address _sfpm) PanopticPoolLiquidity(_sfpm) {}
}
