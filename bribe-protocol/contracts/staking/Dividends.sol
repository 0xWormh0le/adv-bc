//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IDividends.sol";
import "../interfaces/IFeeDistribution.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title Dividends
/// @author contact@bribe.xyz
/// @notice
///
////////////////////////////////////////////////////////////////////////////////////////////

contract Dividends is IDividends, ERC20Votes, Ownable, Pausable, Multicall {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /// @dev minimum deposit to accrue
    uint256 private constant MINIMUM_DEPOSIT = 100 * 1e18;

    /// @dev share scale
    uint256 private constant SHARE_SCALE = 1e12;

    /// @dev reward asset
    IERC20 public immutable rewardAsset;

    /// @dev stake asset
    IERC20 public immutable stakeAsset;

    /// @dev feeDistribution
    address public feeDistribution;

    /// @dev totalDividendsReceived
    uint128 public totalDividendsReceived;

    /// @dev totalStaked
    uint128 public totalStaked;

    /// @dev price peer share
    uint128 public pricePerShare;

    struct UserInfo {
        uint128 pendingReward;
        uint128 lastPricePerShare;
    }

    /// @dev userRewards
    mapping(address => UserInfo) public userRewards;

    constructor(
        address rewardAsset_,
        address stakeAsset_,
        address feeDistribution_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        require(rewardAsset_ != address(0), "INVALID_ASSET");
        require(stakeAsset_ != address(0), "INVALID_STAKE_ASSET");
        require(feeDistribution_ != address(0), "INVALID_FEE_ASSET");

        rewardAsset = IERC20(rewardAsset_);
        stakeAsset = IERC20(stakeAsset_);
        feeDistribution = feeDistribution_;
    }

    /// @dev accrueDividend
    /// @notice calls the fee distribution contract to claim pending dividend
    function accrueDividend() public whenNotPaused {
        _accrueDividendInternal();
    }

    function _accrueDividendInternal() internal {
        uint256 prevBalance = rewardAsset.balanceOf(address(this));

        uint256 amount = IFeeDistribution(feeDistribution).distributeFeeTo(address(this));

        if (amount == 0) return;

        // assert that the amount was transferred
        require(
            rewardAsset.balanceOf(address(this)) - prevBalance >= amount,
            "INVALID_DISTRIBUTION"
        );

        totalDividendsReceived += amount.toUint128();
        uint256 totalStaked_ = totalStaked > 0 ? totalStaked : 1;
        pricePerShare += ((amount * SHARE_SCALE) / totalStaked_).toUint128();

        emit DistributeDividend(amount);
    }

    /// @dev deposit
    /// @param to address to send
    /// @param amount Amount user wants do stake
    /// @param update to distribute pending dividends or not
    function stake(
        address to,
        uint128 amount,
        bool update
    ) external override whenNotPaused {
        require(to != address(0), "INVALID_TO");
        require(amount != 0, "INVALID_AMOUNT");

        if (update || amount > MINIMUM_DEPOSIT || msg.sender != tx.origin) {
            _accrueDividendInternal();
        }

        _accrue(to);

        _mint(to, amount);

        totalStaked += amount;

        stakeAsset.safeTransferFrom(msg.sender, address(this), amount);

        emit Stake(address(this), msg.sender, to, amount);
    }

    /// @dev _accrue
    /// @param user user address to accrue
    function _accrue(address user) internal {
        (uint128 pendingReward, uint128 newPricePerShare) = _calculateUserDividend(user);
        userRewards[user].pendingReward += pendingReward;
        userRewards[user].lastPricePerShare = newPricePerShare;
    }

    /// @dev _beforeTokenTransfer hook
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal override {
        if (from != address(0)) {
            _accrue(from);
        }

        if (to != address(0)) {
            _accrue(to);
        }
    }

    /// @dev _calculateUserDividend
    /// @param user User to calculate their dividend
    function _calculateUserDividend(address user)
        internal
        view
        returns (uint128 pendingReward, uint128 newPricePerShare)
    {
        uint256 lastPricePerShare = userRewards[user].lastPricePerShare;
        uint128 amount = balanceOf(user).toUint128();

        newPricePerShare = pricePerShare;
        if (totalDividendsReceived > 0 && amount > 0) {
            pendingReward = ((amount * (newPricePerShare - lastPricePerShare)) / SHARE_SCALE)
                .toUint128();
        }
    }

    /// @dev unstake
    /// @param amount amount of tokens to unstake
    /// @param update Either to claim pending dividend from fee distribution contract
    function unstake(uint128 amount, bool update) external {
        if (update) _accrueDividendInternal();

        _accrue(msg.sender);

        _burn(msg.sender, amount);
        totalStaked -= amount;

        stakeAsset.safeTransfer(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    /// @dev claimUserDividend
    /// @param update update
    function claimUserDividend(bool update) public whenNotPaused {
        if (update) _accrueDividendInternal();

        _accrue(msg.sender);

        uint256 pendingReward = userRewards[msg.sender].pendingReward;
        if (pendingReward > 0) {
            userRewards[msg.sender].pendingReward = 0;
            rewardAsset.safeTransfer(msg.sender, pendingReward);
        }

        emit ClaimDividend(msg.sender, pendingReward);
    }

    /// @dev rescueFunds
    /// @param asset asset to rescue funds off
    function rescueFunds(IERC20 asset) external onlyOwner {
        require(asset != stakeAsset, "INVALID_ASSET");

        uint256 balance = asset.balanceOf(address(this));

        asset.transfer(msg.sender, balance);

        emit RescueFunds(balance);
    }

    /// @notice pause actions
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause actions
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice setFeeDistributor
    function setFeeDistributor(address newFeeDistribution) external onlyOwner {
        require(newFeeDistribution != address(0), "INVALID_DISTRIBUTOR");

        feeDistribution = newFeeDistribution;

        emit UpdateFeeDistributor(newFeeDistribution);
    }

    /// @dev dividendOf
    /// @param user address of user
    function dividendOf(address user) external view returns (uint256 dividend) {
        (uint128 pendingReward, ) = _calculateUserDividend(user);
        dividend = userRewards[user].pendingReward + pendingReward;
    }
}
