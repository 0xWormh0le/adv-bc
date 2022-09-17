// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@composable-finance/v2-sdk-contracts/contracts/libraries/crosslayer/CrosslayerFunctionCallsLib.sol";


contract PrincipalVault is Ownable {
    using CrosslayerFunctionCallsLib for address;

    address public baseToken;
    address public msgSender;
    address public relayer;
    uint256 public ratio = 5000; // 50%
    uint256 public constant ratioBase = 10000;
    mapping(uint256 => address) releaseVaultAddressByChainId;
    mapping(address => address) releaseVaultPersonaAddress;

    modifier onlyReleaseVaultPersona(){
        require(releaseVaultPersonaAddress[msg.sender] != address(0), "msgsender is not release vault persona");
        _;
    }
    constructor(address _relayer, address _baseToken, address _msgSender) public {
        require(_relayer != address(0), "relayer address 0");
        require(_baseToken != address(0), "releaseToken address 0");
        require(_msgSender != address(0), "msgSender address 0");
        baseToken = _baseToken;
        msgSender = _msgSender;
        relayer = _relayer;
    }


    function setReleaseVaultAddressByChainId(uint256 _chainId, address _relaseVault) public onlyOwner {
        releaseVaultAddressByChainId[_chainId] = _relaseVault;
    }

    function setReleaseVaultAddressPersona(address _persona, address _relaseVault) public onlyOwner {
        releaseVaultPersonaAddress[_persona] = _relaseVault;
    }

    function borrow(uint256 _amount, uint256 _chainId, address _to) external {
        require(IERC20(baseToken).transferFrom(msg.sender, address(this), _amount), "failed to transfer fund from user to this contract");
        require(releaseVaultAddressByChainId[_chainId] != address(0), "fund release contract is not mapped");
        bytes memory _methodData = abi.encodeWithSignature(
           "borrow(amount, address)",
           _to,
           _amount * ratio / ratioBase
        );
        CrosslayerFunctionCallsLib.registerCrossFunctionCall(
            msgSender,
            _chainId,
            releaseVaultAddressByChainId[_chainId],
            _methodData
        );
    }

    function payback(uint256 _amount, address _to) external onlyReleaseVaultPersona{
        require(IERC20(baseToken).transfer(_to, _amount), "failed to payback");
    }
}
