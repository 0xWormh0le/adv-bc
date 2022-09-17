// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@composable-finance/v2-sdk-contracts/contracts/libraries/crosslayer/CrosslayerFunctionCallsLib.sol";


contract CrosslayerVote is Ownable{
    using CrosslayerFunctionCallsLib for address;
    mapping(address => uint256) userVote;
    mapping(uint256 => address) voteCopyAddressByChainId;
    address[] public voteCopyAddresses;

    constructor(address _msgSender) public {
        require(_msgSender != address(0), "msgSender address 0");
        msgSender = _msgSender;
    }

    function setVoteCoyAddressByChainId(uint256 _chainId, address _voteCopy) public onlyOwner {
        voteCopyAddressByChainId[_chainId] = _voteCopy;
        voteCopyAddresses.append(_chainId);
    }

    function vote(uint256 _option) {
        require(userVote[msg.sender] == 0, "User already voted") ;
        userVote[msg.sender] = _option;

        bytes memory _methodData = abi.encodeWithSignature(
           "stake(amount, address)",
           _to,
           _amount * ratio / ratioBase
        );
        for (uint256 i=0; i<voteCopyAddresses.length; i++){
             CrosslayerFunctionCallsLib.registerCrossFunctionCall(
                msgSender,
                _chainId,
                voteCopyAddressByChainId[voteCopyAddresses[i]],
                _methodData
             );

        }
    }
}
