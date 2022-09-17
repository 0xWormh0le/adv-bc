// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "./test.sol";
import "../interfaces/IWETH9.sol";
import "./User.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "../PanopticFactory.sol";
import "../PanopticPoolBeacon.sol";
import {PanopticPool} from "../PanopticPool.sol";
import {SemiFungiblePositionManager} from "../SemiFungiblePositionManager.sol";
import {ReceiptBase} from "../ReceiptBase.sol";
import "../libraries/OptionEncoding.sol";
import "../libraries/BytesLib.sol";

contract PanopticPoolTests is DSTest {
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint24 public constant fee = 3000;

    uint256 public constant ethAmount = 10**20;
    uint256 public constant minEthAmount = 10**15;

    uint256 public constant maxEthAmountToUse = 10**18;
    uint256 public constant minEthAmountToUse = 10**14;

    uint256 public constant maxUsdcAmountToUse = 10**9;
    uint256 public constant minUsdcAmountToUse = 10**6;

    User user1;
    User user2;

    User owner;

    PanopticFactoryV2 panopticFactory;
    PanopticPoolBeacon panopticBeacon;
    PanopticPool panopticPoolImplementation;
    SemiFungiblePositionManager sfpm;
    ReceiptBase receiptBase;

    PanopticPool panpool;

    function setUp() public {
        user1 = new User();
        user2 = new User();
        owner = new User();

        IWETH9(WETH_ADDRESS).deposit{value: ethAmount}();
        IERC20(WETH_ADDRESS).transfer(address(user1), ethAmount);

        IWETH9(WETH_ADDRESS).deposit{value: ethAmount}();
        IERC20(WETH_ADDRESS).transfer(address(user2), ethAmount);

        receiptBase = new ReceiptBase();
        sfpm = new SemiFungiblePositionManager(factory, WETH_ADDRESS);
        panopticPoolImplementation = new PanopticPool(address(sfpm));
        panopticBeacon = new PanopticPoolBeacon(
            address(owner),
            address(panopticPoolImplementation)
        );
        panopticFactory = new PanopticFactoryV2(
            address(panopticBeacon),
            address(owner),
            address(receiptBase),
            factory
        );

        address poolAddress = owner.createPool(panopticFactory, WETH_ADDRESS, USDC_ADDRESS, fee);
        panpool = PanopticPool(payable(poolAddress));

        IWETH9(WETH_ADDRESS).deposit{value: maxEthAmountToUse}();
        IERC20(WETH_ADDRESS).transfer(address(user1), maxEthAmountToUse);
        user1.swapWethForUsdc(maxEthAmountToUse);

        IWETH9(WETH_ADDRESS).deposit{value: maxEthAmountToUse}();
        IERC20(WETH_ADDRESS).transfer(address(user1), maxEthAmountToUse);
        user2.swapWethForUsdc(maxEthAmountToUse);
    }

    function test_swap() public {
        uint256 amountIn = ethAmount - minEthAmount;
        log_named_uint("amountIn", amountIn);
        IUniswapV3Pool pool = user1.getPool();
        (uint160 sqrtPriceX96Before, int24 currentTickBefore, , , , , ) = pool.slot0();
        log_named_uint("sqrtPriceX96Before", sqrtPriceX96Before);
        log_named_int("currentTickBefore", currentTickBefore);

        uint256 usdOut = user1.swapWethForUsdc(amountIn);
        log_named_uint("usdout", usdOut);
        (uint160 sqrtPriceX96After, int24 currentTickAfter, , , , , ) = pool.slot0();
        log_named_uint("sqrtPriceX96After", sqrtPriceX96After);
        log_named_int("currentTickAfter", currentTickAfter);
        require(currentTickAfter > currentTickBefore, "Tick Not Changed");
    }

    function test_swap(uint256 amountIn) public {
        amountIn = minEthAmount + (amountIn % (ethAmount - minEthAmount)); // restrict input size

        user1.swapWethForUsdc(amountIn);
    }

    function test_MMDeposit_MMWithdraw(uint256 ethAmountToDeposit, uint256 usdcAmountToDeposit)
        public
    {
        ethAmountToDeposit =
            minEthAmountToUse +
            (ethAmountToDeposit % (maxEthAmountToUse - minEthAmountToUse));
        usdcAmountToDeposit =
            minUsdcAmountToUse +
            (usdcAmountToDeposit % (maxUsdcAmountToUse - minUsdcAmountToUse));

        user1.approveToken(WETH_ADDRESS, address(panpool), ethAmountToDeposit);
        user1.approveToken(USDC_ADDRESS, address(panpool), usdcAmountToDeposit);

        user1.MMDeposit(
            panpool,
            IPanopticPool.DualTokenAmountParams({
                amount0: usdcAmountToDeposit,
                amount1: ethAmountToDeposit
            }),
            address(user1)
        );

        user1.MMWithdraw(
            panpool,
            IPanopticPool.DualTokenAmountParams({
                amount0: usdcAmountToDeposit,
                amount1: ethAmountToDeposit
            })
        );
    }

    function test_mintOptions() public {
        uint256 ethAmountToDeposit = maxEthAmountToUse;
        uint256 usdcAmountToDeposit = minEthAmountToUse;

        ethAmountToDeposit =
            minEthAmountToUse +
            (ethAmountToDeposit % (maxEthAmountToUse - minEthAmountToUse));
        usdcAmountToDeposit =
            minUsdcAmountToUse +
            (usdcAmountToDeposit % (maxUsdcAmountToUse - minUsdcAmountToUse));

        user1.approveToken(
            WETH_ADDRESS,
            address(panpool),
            ethAmountToDeposit + 176540000000000000000000
        ); // including commision
        user1.approveToken(
            USDC_ADDRESS,
            address(panpool),
            usdcAmountToDeposit + 100000000000000000000000
        ); // including commision

        user1.MMDeposit(
            panpool,
            IPanopticPool.DualTokenAmountParams({
                amount0: usdcAmountToDeposit,
                amount1: ethAmountToDeposit
            }),
            address(user1)
        );

        IUniswapV3Pool unipool = panpool.pool();
        (, int24 currentTick, , , , , ) = unipool.slot0();

        uint16 width = 100;
        int24 strike = currentTick + 1000;
        strike = strike - (strike % 10);

        uint256 tokenId = getOptionTokenId(address(panpool.pool()), strike, width, 3, 1, 1, 4); // token Id generation is not matching the ts code

        user1.MintOptions(panpool, tokenId, 1000000); // number of options = 1000000
    }

    function getOptionTokenId(
        address unipool,
        int24 strike,
        uint16 width,
        uint8 risk_partner,
        uint8 token_type,
        uint8 long_short,
        uint8 ratio
    ) internal pure returns (uint256) {
        bytes memory poolBytes = abi.encodePacked(unipool);
        bytes memory poolId = BytesLib.slice(poolBytes, 0, 10);

        OptionEncoding.OptionConfig[] memory optionData = new OptionEncoding.OptionConfig[](1);
        optionData[0].width = width;
        optionData[0].strike = strike;
        optionData[0].risk_partner = risk_partner;
        optionData[0].token_type = token_type;
        optionData[0].long_short = long_short;
        optionData[0].ratio = ratio;
        return OptionEncoding.encodeID(optionData, BytesLib.toUint80(poolId, 0));
    }
}
