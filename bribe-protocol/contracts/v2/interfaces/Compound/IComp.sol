//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IComp is IERC20 {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function delegate(address to) external;
}
