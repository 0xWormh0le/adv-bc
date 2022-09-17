import { BigNumber, BigNumberish } from "@ethersproject/bignumber";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { IERC20 } from "../compiled-types/IERC20";
import { IERC20__factory } from "../compiled-types/factories/IERC20__factory";
import { IERC20Details } from "../compiled-types/IERC20Details";
import { IERC20Details__factory } from "../compiled-types/factories/IERC20Details__factory";
import { AaveMIMBidHelperV1 as MIMBidHelper } from "../compiled-types/AaveMIMBidHelperV1";
import { AaveMIMBidHelperV1__factory as MIMBidHelper__factory } from "../compiled-types/factories/AaveMIMBidHelperV1__factory";

import { AavePool } from "../compiled-types/AavePool";
import { AavePool__factory } from "../compiled-types/factories/AavePool__factory";

import { MockAaveGovernanceWithTokens } from "../compiled-types/MockAaveGovernanceWithTokens";
import { MockAaveGovernanceWithTokens__factory } from "../compiled-types/factories/MockAaveGovernanceWithTokens__factory";

import { MockAave } from "../compiled-types/MockAave";
import { MockAave__factory } from "../compiled-types/factories/MockAave__factory";

import { MockStkAave } from "../compiled-types/MockStkAave";
import { MockStkAave__factory } from "../compiled-types/factories/MockStkAave__factory";

import { BribeToken } from "../compiled-types/BribeToken";
import { BribeToken__factory } from "../compiled-types/factories/BribeToken__factory";

import { AaveWrapperToken } from "../compiled-types/AaveWrapperToken";
import { AaveWrapperToken__factory } from "../compiled-types/factories/AaveWrapperToken__factory";

import { StkAaveWrapperToken } from "../compiled-types/StkAaveWrapperToken";
import { StkAaveWrapperToken__factory } from "../compiled-types/factories/StkAaveWrapperToken__factory";


describe("Aave MIM BIdding Helper", async () => {
  let snapshotId: any;
  // all addresses belong to mainnet
  let mimTokenAddress: string = "0x99d8a9c45b2eca8864373a26d1459e3dff1e17f3";
  let usdcTokenAddress: string = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";

  let curveMimPool: string = "0x5a6A4D54456819380173272A5E8E9B9904BdF41B";

  let mimWhale: string = "0xA046a8660E66d178eE07ec97c585eeb6aa18c26C"; // account to large mim tokens at forked block
  let mimWhaleSigner: SignerWithAddress;

  let usdcWhale: string = "0xAe2D4617c862309A3d75A0fFB358c7a5009c673F"; // Kraken10
  let usdcWhaleSigner: SignerWithAddress;

  let account1: SignerWithAddress;
  let account2: SignerWithAddress;

  let mimTokenContract: IERC20;
  let usdcTokenContract: IERC20;

  let mimBidHelper: MIMBidHelper;
  let aavePool: AavePool;
  let aaveGovernance: MockAaveGovernanceWithTokens;
  let aaveToken: MockAave;
  let stkAaveToken: MockStkAave;
  let bribeToken: BribeToken;
  let aaveWrapperToken: AaveWrapperToken;
  let stkAaveWrapperToken: StkAaveWrapperToken;

  let amountToTest: BigNumberish = 10000; // 10000 MIM Tokens (without decimals)

  let usdcDecimals: BigNumberish;
  let mimDecimals: BigNumberish;

  let mockProposalId: BigNumberish = 1;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [mimWhale],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [usdcWhale],
    });
    mimWhaleSigner = await ethers.getSigner(mimWhale);
    usdcWhaleSigner = await ethers.getSigner(usdcWhale);
    [account1, account2] = await ethers.getSigners();

    mimTokenContract = await IERC20__factory.connect(mimTokenAddress, account2);
    usdcTokenContract = await IERC20__factory.connect(usdcTokenAddress, account2);

    mimDecimals = await IERC20Details__factory.connect(
      mimTokenContract.address,
      mimWhaleSigner
    ).decimals();
    usdcDecimals = await IERC20Details__factory.connect(
      usdcTokenContract.address,
      usdcWhaleSigner
    ).decimals();

    await mimTokenContract
      .connect(mimWhaleSigner)
      .transfer(
        account1.address,
        BigNumber.from(amountToTest).mul(BigNumber.from(10).pow(mimDecimals))
      );
    await usdcTokenContract
      .connect(usdcWhaleSigner)
      .transfer(
        account1.address,
        BigNumber.from(amountToTest).mul(BigNumber.from(10).pow(usdcDecimals))
      );

    aaveGovernance = await new MockAaveGovernanceWithTokens__factory(account2).deploy();

    aaveToken = await new MockAave__factory(account2).deploy();
    aaveToken.mint("12738263487"); // any random non-zero number
    stkAaveToken = await new MockStkAave__factory(account2).deploy();
    stkAaveToken.mint("76278823"); // any random non-zero number

    aaveGovernance.setReceiptTokens(aaveToken.address, stkAaveToken.address);
    aaveGovernance.createProposal(mockProposalId);

    bribeToken = await new BribeToken__factory(account2).deploy(
      "Bribe Token",
      "BRB",
      "1000000000000000000000000000"
    );
    aaveWrapperToken = await new AaveWrapperToken__factory(account2).deploy();
    stkAaveWrapperToken = await new StkAaveWrapperToken__factory(account2).deploy();

    aavePool = await new AavePool__factory(account2).deploy(
      bribeToken.address,
      aaveToken.address,
      stkAaveToken.address,
      usdcTokenAddress,
      aaveGovernance.address,
      account2.address,
      aaveWrapperToken.address,
      stkAaveWrapperToken.address,
      {
        rewardAmountDistributedPerSecond: 0,
        startTimestamp: 0,
        endTimestamp: 0,
      }
    );
    mimBidHelper = await new MIMBidHelper__factory(account2).deploy(
      usdcTokenAddress,
      aavePool.address
    );
  });

  beforeEach(async () => {
    snapshotId = await hre.network.provider.request({
      method: "evm_snapshot",
      params: [],
    });
  });

  afterEach(async () => {
    await hre.network.provider.request({
      method: "evm_revert",
      params: [snapshotId],
    });
  });

  it("Normal Bid", async () => {
    let account1UsdcBalanceBefore = await usdcTokenContract.balanceOf(account1.address);
    let amountToBid = BigNumber.from(amountToTest).mul(BigNumber.from(10).pow(usdcDecimals));
    await usdcTokenContract.connect(account1).approve(aavePool.address, amountToBid);
    await aavePool.connect(account1).bid(account1.address, 1, amountToBid, true);
    let account1UsdcBalanceAfter = await usdcTokenContract.balanceOf(account1.address);

    expect(account1UsdcBalanceBefore.sub(account1UsdcBalanceAfter)).eq(amountToBid);
  });

  it("Bid using Mim token", async () => {
    let amountToBid = BigNumber.from(amountToTest).mul(BigNumber.from(10).pow(mimDecimals));
    let minUsdcToReceive = BigNumber.from(amountToTest)
      .mul(BigNumber.from(10).pow(usdcDecimals))
      .div(2);
    await mimTokenContract.connect(account1).approve(mimBidHelper.address, amountToBid);

    let mimTokenBalanceBefore = await mimTokenContract.balanceOf(account1.address);
    await mimBidHelper.connect(account1).curveSwapAssetBid({
      token: mimTokenAddress,
      amount: amountToBid,
      minUSDCToReceive: minUsdcToReceive,
      proposalId: mockProposalId,
      support: true,
      curvePoolConfig: { curvePool: curveMimPool, xTokenIndex: 0, yTokenIndex: 2 },
    });
    let mimTokenBalanceAfter = await mimTokenContract.balanceOf(account1.address);
    expect(mimTokenBalanceBefore.sub(mimTokenBalanceAfter)).eq(amountToBid);
    let highestBid = await (await aavePool.bids(mockProposalId)).highestBid;

    // checking if deviate is not more than 1%
    expect(highestBid).to.satisfy((num: BigNumberish) => {
      num = BigNumber.from(num);
      if (num.gt(amountToBid)) {
        return amountToBid.sub(num).lt(amountToBid.div(100));
      } else {
        return num.sub(amountToBid).lt(amountToBid.div(100));
      }
    });
  });
});
