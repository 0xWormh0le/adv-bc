//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IPausable.sol";
import "./interfaces/IBribeRewardGauge.sol";
import "./interfaces/IAsset.sol";
import "./interfaces/IRootTunnel.sol";

abstract contract Asset is IAsset, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev governance token
    IERC20 public immutable override governanceToken;

    /// @dev pool contract
    address public immutable poolContract;

    /// @dev vote contract
    address public immutable override voteContract;

    /// @dev reward gauge
    IBribeRewardGauge public immutable bribeRewardGauge;

    event Deposit(IERC20 indexed token, address indexed user, uint256 amount, uint256 timestamp);

    event Withdraw(IERC20 indexed token, address indexed user, uint256 amount, uint256 timestamp);

    /**
     * @dev constructor
     * @param governanceToken_ governance token address
     * @param bribeRewardGauge_ reward gauge contract address
     * @param poolContract_ pool contract address
     * @param voteContract_ vote contract address
     */
    constructor(
        address governanceToken_,
        address bribeRewardGauge_,
        address poolContract_,
        address voteContract_
    ) ERC20("", "") ReentrancyGuard() {
        require(bribeRewardGauge_ != address(0), "Asset: zero address of reward gauge");
        require(governanceToken_ != address(0), "Asset: zero address of governance token");
        require(poolContract_ != address(0), "Asset: zero address of pool contract");
        require(voteContract_ != address(0), "Asset: zero address of vote contract");

        bribeRewardGauge = IBribeRewardGauge(bribeRewardGauge_);
        governanceToken = IERC20(governanceToken_);
        voteContract = voteContract_;
        poolContract = poolContract_;
    }

    /**
     * @dev deposit governance token
     * @param recipient address to mint the receipt tokens
     * @param amount amount of tokens to deposit
     */
    function deposit(address recipient, uint128 amount) external nonReentrant {
        require(!IPausable(poolContract).paused(), "Asset: pool is paused");
        require(amount > 0, "Asset: invalid amount");

        governanceToken.safeTransferFrom(msg.sender, address(this), amount);

        _delegate();

        // performs check that recipient != address(0)
        _mint(recipient, amount);

        emit Deposit(governanceToken, recipient, amount, block.timestamp);
    }

    /**
     * @dev withdraw governance token
     * @param recipient address to mint the receipt tokens
     * @param amount amount of tokens to deposit
     */
    function withdraw(address recipient, uint128 amount) external nonReentrant {
        require(amount > 0, "Asset: invalid amount");
        require(balanceOf(msg.sender) >= amount, "Asset: invalid balance");

        // burn tokens
        _burn(msg.sender, amount);

        // send back tokens
        governanceToken.safeTransfer(recipient, amount);

        _delegate();

        emit Withdraw(governanceToken, msg.sender, amount, block.timestamp);
    }

    function getMessageToChild() external view returns (bytes memory snapshots) {}

    /*****************************************
        Vitual functions
     *****************************************/

    /**
     * @dev delegates voting power to vote contract
     */
    function _delegate() internal virtual;

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return string(abi.encodePacked("bribe-", IERC20Metadata(address(governanceToken)).name()));
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return string(abi.encodePacked("br", IERC20Metadata(address(governanceToken)).symbol()));
    }

    /// @dev _beforeTokenTransfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == to) {
            return;
        }

        if (from != address(0)) {
            bribeRewardGauge.accrueRewards(from);
        }

        if (to != address(0)) {
            bribeRewardGauge.accrueRewards(to);
        }

        IPool(poolContract).rootTunnel().sendReceiptTokenSnapshot(
            IPool(poolContract).name(),
            from,
            to,
            balanceOf(from),
            balanceOf(to),
            amount,
            block.timestamp
        );
    }
}
