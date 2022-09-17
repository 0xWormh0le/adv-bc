// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@composable-finance/v2-sdk-contracts/contracts/libraries/crosslayer/CrosslayerFunctionCallsLib.sol";


contract CrosslayerFunctionCallsMock {
    using CrosslayerFunctionCallsLib for address;

    function createPersona(address _factoryAddress, address _user) external {
        IMsgReceiverFactory(_factoryAddress).createPersona(_user);
    }

    function saveEth(address _msgReceiverAddress, address _receiver, uint256 _amount) external {
        CrosslayerFunctionCallsLib.saveEth(_msgReceiverAddress, _receiver, _amount);
    }

    function saveNFT(
        address _msgReceiverAddress,
        address _nftContract,
        uint256 _nftId,
        address _receiver
    )
    external
    {
        CrosslayerFunctionCallsLib.saveNFT(_msgReceiverAddress, _nftContract, _nftId, _receiver);
    }

    function saveTokens(
        address _msgReceiverAddress,
        address _token,
        address _receiver,
        uint256 _amount
    ) external {
        CrosslayerFunctionCallsLib.saveTokens(_msgReceiverAddress, _token, _receiver, _amount);
    }


    // msgSender lib
    function registerCrossFunctionCall(
        address _msgSenderAddress,
        uint256 _chainId,
        address _destinationContract,
        bytes calldata _methodData
    )
    external
    {
        return CrosslayerFunctionCallsLib.registerCrossFunctionCall(
            _msgSenderAddress,
            _chainId,
            _destinationContract,
            _methodData
        );
    }
}
