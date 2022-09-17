// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;

pragma abicoder v2;

import "./interfaces/ISemiFungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./libraries/OptionEncoding.sol";

// import "hardhat/console.sol";

/**
 * @title ERC1155 positions
 * @notice Wraps Uniswap V3 positions in the ERC1155 semi-fungible token interface
 */
contract SemiFungiblePositionManager is
    ISemiFungiblePositionManager,
    IUniswapV3MintCallback,
    ERC1155,
    PeripheryImmutableState,
    PeripheryPayments
{
    // details about the option as deployed to the uniswap pool

    struct Option {
        uint128 optionLiquidity;
        uint128 baseLiquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
    }

    struct MintCallbackData {
        PoolAddress.PoolKey poolKey;
        address payer;
    }

    uint24 public constant tickSpacing = 10;

    /// @dev pool id (first 10 bytes) => pool address
    mapping(uint80 => IUniswapV3Pool) public poolIdToAddr;

    /// @dev user => token id => array of options
    mapping(address => mapping(uint256 => Option[])) public options;

    event OptionsMinted(
        uint256 indexed tokenId,
        uint80 indexed poolId,
        uint128 numberOfOptions,
        address recipient,
        address pool
    );

    event OptionsBurnt(
        uint256 indexed tokenId,
        uint80 indexed poolId,
        uint128 numberOfOptions,
        address pool
    );

    fallback() external payable {}

    constructor(address _factory, address _WETH9)
        ERC1155("")
        PeripheryImmutableState(_factory, _WETH9)
    {}

    /// @inheritdoc IUniswapV3MintCallback
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        CallbackValidation.verifyCallback(factory, decoded.poolKey);

        if (amount0Owed > 0) pay(decoded.poolKey.token0, decoded.payer, msg.sender, amount0Owed);
        if (amount1Owed > 0) pay(decoded.poolKey.token1, decoded.payer, msg.sender, amount1Owed);
    }

    function getOptions(address user, uint256 tokenId) external view returns (Option[] memory) {
        return options[user][tokenId];
    }

    // Deploy all liquidity for a given tokenId (up to 4 positions)

    function mintOptionsPosition(
        uint256 tokenId,
        uint128 numberOfOptions,
        address recipient,
        IUniswapV3Pool pool
    ) external payable override {
        _mintOptionsPosition(tokenId, numberOfOptions, recipient, pool);
    }

    function burnOptionsPosition(uint256 tokenId)
        external
        payable
        override
        returns (uint128 balance)
    {
        balance = _burnOptionsPosition(tokenId);
    }

    function _mintOptionsPosition(
        uint256 tokenId,
        uint128 numberOfOptions,
        address recipient,
        IUniswapV3Pool pool
    ) internal {
        require(numberOfOptions > 0, "SFPM: zero number of options");
        require(balanceOf(msg.sender, tokenId) == 0, "SFPM: already minted");

        Option[] storage _options = options[msg.sender][tokenId];

        (uint80 poolId, OptionEncoding.OptionConfig[] memory optionConfigs) = OptionEncoding
            .decodeID(tokenId);

        require(uint256(address(pool)) >> 80 == uint256(poolId), "SFPM: invalid pool id");
        require(optionConfigs[0].ratio > 0, "SFPM: zero ratio");

        bytes memory mintdata = abi.encode(
            MintCallbackData({
                poolKey: PoolAddress.PoolKey({
                    token0: pool.token0(),
                    token1: pool.token1(),
                    fee: pool.fee()
                }),
                payer: msg.sender
            })
        );

        // loop through the 4 positions in the tokenId
        for (uint256 i = 0; i < 4; i++) {
            OptionEncoding.OptionConfig memory optionData = optionConfigs[i];

            if (optionData.ratio == 0) {
                continue;
            }

            uint128 optionLiquidity = numberOfOptions * optionData.ratio;

            // Compute the upper and lower ticks
            int24 tickLower = optionData.strike - int24(optionData.width * tickSpacing);
            int24 tickUpper = optionData.strike + int24(optionData.width * tickSpacing);

            pool.mint(address(this), tickLower, tickUpper, optionLiquidity, mintdata);

            (
                uint128 baseLiquidity,
                uint256 feeGrowthInside0LastX128,
                uint256 feeGrowthInside1LastX128,
                ,

            ) = pool.positions(PositionKey.compute(address(this), tickLower, tickUpper));

            _options.push(
                Option(
                    optionLiquidity,
                    baseLiquidity,
                    feeGrowthInside0LastX128,
                    feeGrowthInside1LastX128
                )
            );
        }

        // create the ERC1155 token (_mint from ERC1155 interface)
        _mint(recipient, tokenId, numberOfOptions, "");
        poolIdToAddr[poolId] = pool;

        emit OptionsMinted(tokenId, poolId, numberOfOptions, recipient, address(pool));
    }

    // Remove all liquidity for a given tokenId (do not allow partial burns)
    function _burnOptionsPosition(uint256 tokenId) internal returns (uint128) {
        uint128 balance = uint128(balanceOf(msg.sender, tokenId));

        require(balance > 0, "SFPM: no option minted");

        Option[] storage _options = options[msg.sender][tokenId];

        (uint80 poolId, OptionEncoding.OptionConfig[] memory optionConfigs) = OptionEncoding
            .decodeID(tokenId);

        IUniswapV3Pool pool = poolIdToAddr[poolId];

        // Loop through each option position in the tokenId
        uint256 j = 0;

        for (uint256 i = 0; i < 4; i++) {
            OptionEncoding.OptionConfig memory optionData = optionConfigs[i];

            if (optionData.ratio == 0) {
                continue;
            }

            // Compute the upper and lower ticks
            int24 tickLower = optionData.strike - int24(optionData.width * tickSpacing);
            int24 tickUpper = optionData.strike + int24(optionData.width * tickSpacing);

            // Burn the liquidity in the Uniswap pool
            pool.burn(tickLower, tickUpper, _options[j].optionLiquidity);
            j += 1;
        }

        _burn(msg.sender, tokenId, balance);
        delete options[msg.sender][tokenId];

        emit OptionsBurnt(tokenId, poolId, balance, address(pool));

        return balance;
    }

    function rollOption(
        uint256 oldTokenId,
        uint256 newTokenId,
        address recipient,
        IUniswapV3Pool pool
    ) external payable returns (uint128 numberOfOptions) {
        // burn the old position
        numberOfOptions = _burnOptionsPosition(oldTokenId);

        // mint the new position
        _mintOptionsPosition(newTokenId, numberOfOptions, recipient, pool);
    }
}
