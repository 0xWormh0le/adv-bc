import { ethers } from "hardhat";
import { expect } from "chai";
import {
  SemiFungiblePositionManager,
  SemiFungiblePositionManager__factory,
  UniswapV3Pool,
  UniswapV3Pool__factory,
  Token,
  Token__factory,
} from "../types";
import * as OptionEncoding from "./libraries/OptionEncoding";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("SemiFungiblePositionManager", function () {
  let positionManager: SemiFungiblePositionManager;
  let token0: Token;
  let token1: Token;
  let pool: UniswapV3Pool;
  let users: SignerWithAddress[];

  before(async () => {
    const PositionManager = (await ethers.getContractFactory(
      "SemiFungiblePositionManager"
    )) as SemiFungiblePositionManager__factory;
    const UniswapV3Pool = (await ethers.getContractFactory(
      "UniswapV3Pool"
    )) as UniswapV3Pool__factory;
    const Token = (await ethers.getContractFactory("Token")) as Token__factory;

    token0 = await Token.deploy();
    token1 = await Token.deploy();

    positionManager = await PositionManager.deploy(
      ethers.constants.AddressZero,
      ethers.constants.AddressZero
    );

    pool = await UniswapV3Pool.deploy(token0.address, token1.address, 0);

    users = await ethers.getSigners();
  });

  it("option mint fails: invalid pool id", async () => {
    const numberOfOptions = 3;
    const [alice] = users;

    const tokenId = OptionEncoding.encodeID(BigInt(0), [
      { width: 0, strike: 0, riskPartner: 0, ratio: 0, tokenType: true, longShort: true },
    ]);

    await expect(
      positionManager
        .connect(alice)
        .mintOptionsPosition(tokenId, numberOfOptions, users[0].address, pool.address)
    ).to.revertedWith("SFPM: invalid pool id");
  });

  it("option mint fails: zero ratio", async () => {
    const numberOfOptions = 3;
    const [alice] = users;

    const tokenId = OptionEncoding.encodeID(
      BigInt(pool.address.slice(0, 22).toLowerCase()), // extract first 10 bytes for pool id
      [{ width: 0, strike: 0, riskPartner: 0, ratio: 0, tokenType: true, longShort: true }]
    );

    await expect(
      positionManager
        .connect(alice)
        .mintOptionsPosition(tokenId.toString(), numberOfOptions, users[0].address, pool.address)
    ).to.revertedWith("SFPM: zero ratio");
  });

  it("option mint succeeds", async () => {
    const numberOfOptions = 3;
    const [alice] = users;

    const tokenId = OptionEncoding.encodeID(
      BigInt(pool.address.slice(0, 22).toLowerCase()), // extract first 10 bytes for pool id
      [{ width: 1, strike: 2, riskPartner: 3, ratio: 4, tokenType: true, longShort: true }]
    );

    await expect(
      positionManager
        .connect(alice)
        .mintOptionsPosition(tokenId.toString(), numberOfOptions, users[0].address, pool.address)
    ).to.emit(positionManager, "OptionsMinted");
  });

  it("option count after mint", async () => {
    const [alice] = users;

    const tokenId = OptionEncoding.encodeID(
      BigInt(pool.address.slice(0, 22).toLowerCase()), // extract first 10 bytes for pool id
      [{ width: 1, strike: 2, riskPartner: 3, ratio: 4, tokenType: true, longShort: true }]
    );

    expect((await positionManager.getOptions(alice.address, tokenId)).length).to.equal(1);
  });

  it("option mint again fails: already minted", async () => {
    const numberOfOptions = 3;
    const [alice] = users;

    const tokenId = OptionEncoding.encodeID(
      BigInt(pool.address.slice(0, 22).toLowerCase()), // extract first 10 bytes for pool id
      [{ width: 1, strike: 2, riskPartner: 3, ratio: 4, tokenType: true, longShort: true }]
    );

    await expect(
      positionManager
        .connect(alice)
        .mintOptionsPosition(tokenId.toString(), numberOfOptions, users[0].address, pool.address)
    ).to.revertedWith("SFPM: already minted");
  });

  it("option burn fails: no option minted", async () => {
    const [alice] = users;

    const tokenId = OptionEncoding.encodeID(
      BigInt(pool.address.slice(0, 22).toLowerCase()), // extract first 10 bytes for pool id
      [{ width: 0, strike: 0, riskPartner: 0, ratio: 9, tokenType: true, longShort: true }]
    );

    await expect(positionManager.connect(alice).burnOptionsPosition(tokenId)).to.revertedWith(
      "SFPM: no option minted"
    );
  });

  it("option burn succeeds", async () => {
    const [alice] = users;
    const numberOfOptions = 3;
    const poolId = pool.address.slice(0, 22).toLowerCase();

    const tokenId = OptionEncoding.encodeID(
      BigInt(poolId), // extract first 10 bytes for pool id
      [{ width: 1, strike: 2, riskPartner: 3, ratio: 4, tokenType: true, longShort: true }]
    );

    await expect(positionManager.connect(alice).burnOptionsPosition(tokenId))
      .to.emit(positionManager, "OptionsBurnt")
      .withArgs(tokenId, poolId, numberOfOptions, pool.address);
  });

  it("option count after burn", async () => {
    const [alice] = users;

    const tokenId = OptionEncoding.encodeID(
      BigInt(pool.address.slice(0, 22).toLowerCase()), // extract first 10 bytes for pool id
      [{ width: 1, strike: 2, riskPartner: 3, ratio: 4, tokenType: true, longShort: true }]
    );

    expect((await positionManager.getOptions(alice.address, tokenId)).length).to.equal(0);
  });
});
