//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAsset is IERC20 {
    function voteContract() external view returns (address);

    function governanceToken() external view returns (IERC20);
}
