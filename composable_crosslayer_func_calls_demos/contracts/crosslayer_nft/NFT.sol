// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NFTToken is Ownable{
    function mint(address to, uint256 tokenId) onlyOwner {
        _mint(to, tokenId);
    }
}
