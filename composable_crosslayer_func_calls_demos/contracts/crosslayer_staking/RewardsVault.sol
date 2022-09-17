// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract RewardsVault is ERC20{

    address public rewardToken;
    address public msgSender;
    uint256 public ratio = 5000; // 50%
    uint256 public constant ratioBase = 10000;
    uint256 public chainId;
    address public principalVaultPersona;

    modifier onlyPrincipalVaultPersona(){
        require(msg.sender == principalVaultPersona, "only principal vault");
        _;
    }

    constructor(address _rewardToken, address _msgSender, address _principalVaultPersona) public {
        require(_rewardToken != address(0), "rewardToken address 0");
        require(_msgSender != address(0), "msgSender address 0");
        require(_principalVaultPersona != address(0), "principalVaultPersona address 0");

        rewardToken = _rewardToken;
        msgSender = _msgSender;
        principalVaultPersona = _principalVaultPersona;
    }

    // prevent user to transfer share token
    function transfer(address, uint256) override public {
        revert();
    }

    // prevent user to transfer share token
    function transferFrom(address, address, uint256) override public {
        revert();
    }

    function stake(uint256 _amount, address _to) external onlyPrincipalVaultPersona {
        //_updateAccruedRewards();
        _mint(_to, _amount);
   }

    function claim(uint256 _amount, address _to) external {
        //_updateAccruedRewards();
        uint256 totalReward; // getUserCurrentReward(_to);
        require(_amount <= totalReward, 'insufficient reward');
        //updateUserReward(_to, totalReward-_amount);
        ERC20(rewardToken).transfer(_to, _amount);
    }


    function unstake(uint256 _amount, address _to) external onlyPrincipalVaultPersona {
        //_updateAccruedRewards();
        _burn(_to, _amount);
    }
}
