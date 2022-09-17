// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@composable-finance/v2-sdk-contracts/contracts/libraries/crosslayer/CrosslayerFunctionCallsLib.sol";


contract ReleaseVault {
    using CrosslayerFunctionCallsLib for address;

    address public releaseToken;
    address public msgSender;
    address public relayer;
    uint256 public ratio = 5000; // 50%
    uint256 public constant ratioBase = 10000;
    uint256 public chainId;
    address public principalVault;
    address public principalVaultPersona;

    modifier onlyPrincipalVaultPersona(){
        require(msg.sender == principalVaultPersona, "onlyRelayer");
        _;
    }
    constructor(address _relayer, address _releaseToken, address _msgSender, address _principalVault, uint256 _chainId, address _principalVaultPersona) public {
        require(_relayer != address(0), "relayer address 0");
        require(_releaseToken != address(0), "releaseToken address 0");
        require(_msgSender != address(0), "msgSender address 0");
        require(_principalVault != address(0), "principalVault address 0");
        require(_principalVaultPersona != address(0), "principalVaultPersona address 0");

        releaseToken = _releaseToken;
        msgSender = _msgSender;
        chainId = _chainId;
        principalVault = _principalVault;
        principalVaultPersona = _principalVaultPersona;
        relayer = _relayer;
    }

    function borrow(uint256 _amount, address _to) external onlyPrincipalVaultPersona{
        require(IERC20(releaseToken).transfer(address(_to), _amount), "failed to release borrowed fund");
    }

    function payback(uint256 _amount, address _to) external {
        require(IERC20(releaseToken).transferFrom(msg.sender, address(this), _amount), "failed to payback from user");
        bytes memory _methodData = abi.encodeWithSignature(
           "payback(amount, address)",
           _to,
           _amount * ratioBase / ratio
        );
        CrosslayerFunctionCallsLib.registerCrossFunctionCall(
            msgSender,
            chainId,
            principalVault,
            _methodData
        );
    }
}
