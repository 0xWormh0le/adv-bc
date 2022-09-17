//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "../interfaces/IAavePool.sol";
import "../interfaces/Curve/ICurvePool.sol";

/**
 * @notice Bid Helper. Contract to Bid to aave pool using other tokens
 */
contract AaveMIMBidHelperV1 {
    using SafeERC20 for IERC20;

    struct CurvePoolConfig {
        ICurvePool curvePool; // address of the curve pool
        int128 xTokenIndex; // i token index for the curve pool
        int128 yTokenIndex; // j token index for the curve pool
    }

    struct Bid {
        IERC20 token; // token to swap from curve pool
        uint256 amount; // amount of tokens
        uint256 minUSDCToReceive; // minimum USDC to receive after swapping from the pool
        uint256 proposalId; // proposal to bid against
        bool support; // support for the proposal
        CurvePoolConfig curvePoolConfig; // curve pool details
    }

    /**
     * @notice Event emitted when Bid is submitted from the helper contract
     */
    event BidWithOtherAsset(
        IERC20 indexed token,
        address indexed bidder,
        uint256 proposalId,
        bool support,
        uint256 amountInBidAsset,
        uint256 usdcPlacedInBid
    );

    /**
     * @notice Address of the USDC tokens
     */
    IERC20 public immutable usdcToken;
    /**
     * @notice Address of the Aave Bribe Pool
     */
    IAavePool public immutable aaveBribePool;

    /**
     * @notice Constructor
     * @param _usdcToken Address of the USDC token
     * @param _aaveBribePool Address of the Aave Bribe Pool
     */
    constructor(IERC20 _usdcToken, IAavePool _aaveBribePool) {
        usdcToken = _usdcToken;
        aaveBribePool = _aaveBribePool;
    }

    /**
     * @notice Swap tokens from curve and then bid against Aave Pool
     * @param bid Details of the bid
     * @return amount bid to the aave pool
     */
    function curveSwapAssetBid(Bid calldata bid) external returns (uint256) {
        return
            _curveSwapAssetBid(
                bid.token,
                bid.amount,
                bid.minUSDCToReceive,
                bid.proposalId,
                bid.support,
                bid.curvePoolConfig
            );
    }

    /**
     * @notice Swap tokens from curve and then bid against Aave Pool using permit function from ERC20Permit
     * @param bid Details of the bid
     * @return amount bid to the aave pool
     */
    function curveSwapAssetBidWithPermit(
        Bid calldata bid,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        IERC20Permit(address(bid.token)).permit(owner, spender, value, deadline, v, r, s);
        return
            _curveSwapAssetBid(
                bid.token,
                bid.amount,
                bid.minUSDCToReceive,
                bid.proposalId,
                bid.support,
                bid.curvePoolConfig
            );
    }

    /**
     * @notice Internal functions to place the bid
     * @param _token address of the token to swap
     * @param _amount amount of tokens to swap
     * @param _minUSDCToReceive Minimum number of USDC to receive after swapping
     * @param proposalId proposal to bid
     * @param support Support for the proposal
     * @return amount bid to the aave pool
     */
    function _curveSwapAssetBid(
        IERC20 _token,
        uint256 _amount,
        uint256 _minUSDCToReceive,
        uint256 proposalId,
        bool support,
        CurvePoolConfig calldata curvePoolConfig
    ) internal returns (uint256) {
        require(_minUSDCToReceive != 0, "Min USDT to receive should be non zero");
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _token.safeApprove(address(curvePoolConfig.curvePool), _amount);

        uint256 tokensReceived = curvePoolConfig.curvePool.exchange_underlying(
            curvePoolConfig.xTokenIndex,
            curvePoolConfig.yTokenIndex,
            _amount,
            _minUSDCToReceive
        );
        require(
            tokensReceived >= _minUSDCToReceive,
            "amount received should be more than min usdc requested"
        );

        usdcToken.approve(address(aaveBribePool), tokensReceived);
        aaveBribePool.bid(msg.sender, proposalId, uint128(tokensReceived), support);
        emit BidWithOtherAsset(_token, msg.sender, proposalId, support, _amount, tokensReceived);
        return tokensReceived;
    }
}
