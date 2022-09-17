// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NFT.sol";


contract NFTRewardsVault is ERC20 {

    address public msgSender;
    uint256 public POINTS_PER_NFT = 100000;
    address public principalVaultPersona;
    NFTToken public nft;
    mapping (address => uint256) rewardPoints;

    modifier onlyPrincipalVaultPersona(){
        require(msg.sender == principalVaultPersona, "only principal vault");
        _;
    }

    constructor(address _msgSender, address _principalVaultPersona) public {
        require(_msgSender != address(0), "msgSender address 0");
        require(_principalVaultPersona != address(0), "principalVaultPersona address 0");

        nft = new NFTToken();
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
        //_updateAccruedRewards(); // user rewardPoints
        _mint(_to, _amount);
   }

    function mintNFT(uint256 _tokenId, address _to) external {
        //_updateAccruedRewards(); // user rewardPoints
        uint256 totalReward; // getUserCurrentReward(_to);
        require(_amount <= totalReward, 'insufficient reward');
        //updateUserReward(_to, totalReward-_amount);
        require(rewardPoints[msg.sender] > POINTS_PER_NFT, "insufficient reward points");
        rewardPoints[msg.sender] = rewardPoints[msg.sender] - POINTS_PER_NFT;
        nft.mint(_to, _tokenId);
    }


    function unstake(uint256 _amount, address _to) external onlyPrincipalVaultPersona {
        //_updateAccruedRewards(); // user rewardPoints
        _burn(_to, _amount);
    }
}
