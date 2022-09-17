// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract CrosslayerVoteCopy {

    address public crosslayerVotePersona;
    mapping(address => uint256) public userVote;

    modifier onlyCrosslayerVotePersona(){
        require(msg.sender == crosslayerVotePersona, "only crosslayer vote address");
        _;
    }

    constructor(address _msgSender, address _crosslayerVotePersona) public {
        require(_msgSender != address(0), "msgSender address 0");
        require(_crosslayerVotePersona != address(0), "crosslayerVotePersona address 0");

        msgSender = _msgSender;
        crosslayerVotePersona = _crosslayerVotePersona;
    }

    function getVote(address _user, uint256 _vote) external onlyCrosslayerVotePersona {
        userVote[_user] = _vote;
    }
}
