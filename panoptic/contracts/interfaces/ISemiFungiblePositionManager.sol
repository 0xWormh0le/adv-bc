// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISemiFungiblePositionManager is IERC1155 {
    function mintOptionsPosition(
        uint256 tokenId,
        uint128 numberOfOptions,
        address recipient,
        IUniswapV3Pool pool
    ) external payable;

    function burnOptionsPosition(uint256 tokenId) external payable returns (uint128 balance);
}
