// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@composable-finance/v2-sdk-contracts/contracts/libraries/crosslayer/CrosslayerFunctionCallsLib.sol";


contract StakingVault is Ownable{
    using CrosslayerFunctionCallsLib for address;

    address public baseToken;
    address public msgSender;
    uint256 public ratio = 5000; // 50%
    uint256 public constant ratioBase = 10000;
    mapping(uint256 => address) rewardVaultAddressByChainId;
    mapping(address => uint256) userBalances;

    constructor(address _baseToken, address _msgSender) public {
        require(_baseToken != address(0), "rewardToken address 0");
        require(_msgSender != address(0), "msgSender address 0");
        baseToken = _baseToken;
        msgSender = _msgSender;
    }


    function setRewardVaultAddressByChainId(uint256 _chainId, address _relaseVault) public onlyOwner {
        rewardVaultAddressByChainId[_chainId] = _relaseVault;
    }

    function stake(uint256 _amount, uint256 _chainId, address _to) external {
        require(IERC20(baseToken).transferFrom(msg.sender, address(this), _amount), "failed to transfer fund from user to this contract");
        require(rewardVaultAddressByChainId[_chainId] != address(0), "reward contract is not mapped");
        userBalances[_to] += _amount;
        bytes memory _methodData = abi.encodeWithSignature(
           "stake(amount, address)",
           _to,
           _amount * ratio / ratioBase
        );
        CrosslayerFunctionCallsLib.registerCrossFunctionCall(
            msgSender,
            _chainId,
            rewardVaultAddressByChainId[_chainId],
            _methodData
        );
    }

    function unstake(uint256 _amount, address _to, uint256 _chainId) external{
        require(userBalances[msg.sender] > _amount, "insufficient amount");
        userBalances[_to] = userBalances[_to] - _amount;
        require(IERC20(baseToken).transfer(_to, _amount), "failed to unstake");
        bytes memory _methodData = abi.encodeWithSignature(
           "unstake(amount, address)",
           _to,
           _amount * ratio / ratioBase
        );
        CrosslayerFunctionCallsLib.registerCrossFunctionCall(
            msgSender,
            _chainId,
            rewardVaultAddressByChainId[_chainId],
            _methodData
        );
    }
}
