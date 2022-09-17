//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import './ChiselBase.sol';
import './external/library/Math.sol';

//////////////////////////////////////////
/// @title ChiselInterest
/// @notice Interest distribution contract
//////////////////////////////////////////
abstract contract ChiselInterest is ChiselBase {
    uint256 private constant DISTRIBUTION_PERIOD = 45_800; // ~ 7 days
    uint256 private rewardPerToken;
    uint256 private lastAccrualBlock;
    uint256 private lastIncomeBlock;
    uint256 private rewardRateStored;
    mapping(address => uint256) private rewardSnapshot;

    /// @notice set incentive call percent
    /// @param _value percent of income that will be sent to the caller (100% = 10000)
    function setCallIncentive(uint256 _value) external onlyAdmin {
        require(_value != 0 && _value < 5000, 'setCallIncentive: Invalid value');

        callIncentive = _value;
        emit NewCallIncentiveSet(_value);
    }

    /// @dev If no new income is added for more than DISTRIBUTION_PERIOD blocks,
    /// then do not distribute any more rewards
    function rewardRate() public view returns (uint256) {
        uint256 blocksElapsed = block.number - lastIncomeBlock;

        if (blocksElapsed < DISTRIBUTION_PERIOD) {
            return rewardRateStored;
        } else {
            return 0;
        }
    }

    function pendingAccountReward(address _account) public view returns (uint256) {
        uint256 pedingRewardPerToken = rewardPerToken + _pendingRewardPerToken();
        uint256 rewardPerTokenDelta = pedingRewardPerToken - rewardSnapshot[_account];
        return (rewardPerTokenDelta * balanceOf(_account)) / 1e18;
    }

    function _pendingRewardPerToken() internal view returns (uint256) {
        if (lastAccrualBlock == 0 || _totalSupply == 0) {
            return 0;
        }

        uint256 blocksElapsed = block.number - lastAccrualBlock;
        return (blocksElapsed * rewardRate() * 1e18) / _totalSupply;
    }

    function _accrue() internal {
        rewardPerToken += _pendingRewardPerToken();
        lastAccrualBlock = block.number;
    }

    function claim(address _account) public {
        _accrue();
        uint256 pendingReward = pendingAccountReward(_account);

        if (pendingReward > 0) {
            _mint(_account, pendingReward);
            emit Claim(_account, pendingReward);
        }

        rewardSnapshot[_account] = rewardPerToken;
    }

    /// @notice Update rewardRateStored to distribute previous unvested income + new income
    /// over te next DISTRIBUTION_PERIOD blocks
    /// @param _addAmount part of pairIncome that is being added to distribute
    function addIncome(uint256 _addAmount) internal {
        _accrue();

        uint256 blocksElapsed = Math.min(DISTRIBUTION_PERIOD, block.number - lastIncomeBlock);
        uint256 unvestedIncome = rewardRateStored * (DISTRIBUTION_PERIOD - blocksElapsed);

        rewardRateStored = (unvestedIncome + _addAmount) / DISTRIBUTION_PERIOD;
        lastIncomeBlock = block.number;

        emit NewIncome(_addAmount, rewardRateStored);
    }
}
