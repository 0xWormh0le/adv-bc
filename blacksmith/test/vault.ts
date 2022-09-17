import { ethers, waffle } from "hardhat";
import { Signer } from "ethers";
import { expect, assert } from "chai";
import {
  Vault,
  MockToken
} from "../types";
import { IAccount, LendingPairHelpers, runTestSuite, TestVars } from "./lib";
import { signVaultApproveContractMessage } from "../helpers/message";
import { EthereumAddress } from "../helpers/types";

const flashLoanRate = ethers.utils.parseUnits("0.05", 18);
const BASE = ethers.utils.parseUnits("1", 18);
const amountToDeposit = 100
const sharesToTransfer = 5

const initializeVault = (vault: Vault, user: IAccount) =>  vault.initialize(flashLoanRate, user.address);

const setupAccountBalance = async (asset: MockToken, accounts: EthereumAddress[], amount ?: number) => {
  await Promise.all(accounts.map((account) => asset.setBalanceTo(account, amount || amountToDeposit)))
}

const setupAccountBalanceAndVaultDeposit = async(vault: Vault, asset: MockToken, accounts: IAccount[], amount ?: number) => {
  await setupAccountBalance(asset, accounts.map(account => account.address), amount)

  await Promise.all(accounts.map(async (account) => {
    await asset.connect(account.signer).approve(vault.address, amount || amountToDeposit);
    await vault.connect(account.signer).deposit(asset.address, account.address, account.address, amount || amountToDeposit)
  }))
}

runTestSuite("Vault", (vars: TestVars) => {
  
  it("initialize fails with 0 team", async () => {
    const { Vault } = vars
    await expect(
      Vault.initialize(flashLoanRate, ethers.constants.AddressZero)
    ).to.be.revertedWith("INVALID_OWNER");
  });

  it("initialize - correctly", async () => {
    const { Vault, accounts: [admin]} = vars

    await Vault.initialize(flashLoanRate, admin.address);

    expect(await Vault.flashLoanRate()).to.eq(flashLoanRate);
    expect(await Vault.owner()).to.eq(admin.address);
  });

  it("version", async () => {
    const { Vault } = vars
    expect((await Vault.version()).toString()).to.eq("1");
  });

  it("name", async () => {
    const { Vault } = vars
    expect((await Vault.name()).toString()).to.eq("WarpVault v1");
  });

  it("proxiableUUID", async () => {
    const { Vault } = vars
    let messageBytes = ethers.utils.toUtf8Bytes(
      "org.warp.contracts.warpvault.implementation"
    );
    const hash = ethers.utils.keccak256(messageBytes);
    expect((await Vault.proxiableUUID()).toString()).to.eq(hash.toString());
  });

  it("pause & unpause - fails incorrect user", async function() {
    const { Vault, accounts: [admin,  bob]} = vars
    await initializeVault(Vault, admin)

    await expect(
      Vault.connect(bob.signer).pause()
    ).to.be.revertedWith("ONLY_OWNER")
    
    await expect(
      Vault.connect(bob.signer).unpause()
    ).to.be.revertedWith("ONLY_OWNER")
  })

  it("pause", async function() {
    const { Vault, BorrowAsset, accounts: [admin,  bob]} = vars
    await initializeVault(Vault, admin)

    expect(
      await Vault.paused()
    ).to.eq(false)

    // pause the contract
    expect(
      await Vault.pause()
    ).to.emit(Vault, 'Paused').withArgs(
      admin.address
    )

    // cannot perform deposit, withdraw or transfer actions
    await expect(
      Vault.deposit(
        BorrowAsset.address,
        admin.address,
        ethers.constants.AddressZero,
        amountToDeposit
      )
    ).to.be.revertedWith("Pausable: paused")

    await expect(
      Vault.withdraw(
        BorrowAsset.address,
        admin.address,
        ethers.constants.AddressZero,
        amountToDeposit
      )
    ).to.be.revertedWith("Pausable: paused")

    await expect(
      Vault.transfer(
        BorrowAsset.address,
        admin.address,
        ethers.constants.AddressZero,
        amountToDeposit
      )
    ).to.be.revertedWith("Pausable: paused")
    expect(
      await Vault.paused()
    ).to.eq(true)

    expect(
      await Vault.unpause()
    ).to.emit(Vault, 'Unpaused').withArgs(
      admin.address
    )

    expect(
      await Vault.paused()
    ).to.eq(false)

  })

  it('approveContract - fails invalid to / fails with wrong signature ', async () => {
    const { Vault, accounts: [admin,  bob]} = vars
    const vaultDetails = { 
      name: await Vault.name(),
      address: Vault.address,
      chainId: (await ethers.provider.getNetwork()).chainId,
      version: await Vault.version()
    };

    const nonce = (await Vault.userApprovalNonce(admin.address)).toNumber()
    const { v, r, s } = await signVaultApproveContractMessage(
      admin.privateKey,
      vaultDetails,
      {
          approve: true,
          user: admin.address,
          nonce,
          contract: bob.address
      }
    )

    await expect(
      Vault.connect(bob.signer).approveContract(
        admin.address,
        ethers.constants.AddressZero,
        true,
        v,
        r,
        s
    )).to.be.revertedWith("INVALID_CONTRACT")

    await expect(
      Vault.connect(bob.signer).approveContract(
        bob.address,
        admin.address,
        true,
        v,
        r,
        s
    )).to.be.revertedWith("INVALID_SIGNATURE")
  })

  it('approveContract', async() => {
    const { Vault, BorrowAsset, LendingPair, PriceOracleAggregator, accounts: [admin,  bob]} = vars
    const lendingPairHelpers = LendingPairHelpers(Vault, LendingPair, BorrowAsset, BorrowAsset, PriceOracleAggregator, admin)
    
    const nonce = (await Vault.userApprovalNonce(admin.address)).toNumber()
    expect(
      await Vault.userApprovedContracts(bob.address, admin.address)
    ).to.eq(false)

    // approve contract
    expect(
      await lendingPairHelpers.approveInVault(admin, bob.address, true)
    ).to.emit(Vault, "Approval")
    .withArgs(
      admin.address,
      bob.address,
      true,
    );

    // expect nonce to be incremented
    const newNonce = (await Vault.userApprovalNonce(admin.address)).toNumber()
    expect(newNonce).to.eq(nonce + 1)
    
    // read the status onchain
    expect(
      await Vault.userApprovedContracts(admin.address, bob.address)
    ).to.eq(true)

    // un-approve contract
    await expect(
      await lendingPairHelpers.approveInVault(admin, bob.address, false)
    ).to.emit(Vault, "Approval")
    .withArgs(
      admin.address,
      bob.address,
      false,
    );
    
    // read the status onchain
    expect(
      await Vault.userApprovedContracts(bob.address, admin.address)
    ).to.eq(false)
  
  })

  it("deposit fails with invalid `to` address", async () => {
    const { Vault, BorrowAsset, accounts: [admin,  bob]} = vars
    await initializeVault(Vault, admin)
    await expect(
      Vault.deposit(
        BorrowAsset.address,
        admin.address,
        ethers.constants.AddressZero,
        amountToDeposit
      )
    ).to.be.revertedWith("INVALID_TO_ADDRESS");
  });

  it("deposit - correctly with correct user balance", async () => {
    const { Vault, BorrowAsset, accounts: [admin,  bob]} = vars
    await initializeVault(Vault, admin)
    // set balance
    await BorrowAsset.setBalanceTo(admin.address, amountToDeposit);
    // approve Vault to take 100
    await BorrowAsset.approve(Vault.address, amountToDeposit);

    await expect(
      await Vault.deposit(BorrowAsset.address, admin.address, admin.address, amountToDeposit)
    )
      .to.emit(Vault, "Deposit")
      .withArgs(
        BorrowAsset.address,
        admin.address,
        admin.address,
        amountToDeposit,
        amountToDeposit
      );

    expect(
      await (await Vault.balanceOf(BorrowAsset.address, admin.address)).toNumber()
    ).eq(amountToDeposit);

    expect((await Vault.totals(BorrowAsset.address)).toNumber()).eq(
      amountToDeposit
    );
  });

  it("deposit fails with incorrect approve deposit", async () => {
    const { Vault, BorrowAsset, accounts: [admin]} = vars
    await initializeVault(Vault, admin)

    await expect(
      Vault.deposit(BorrowAsset.address, admin.address, admin.address, 10000000)
    ).to.be.reverted;
  });

  it("transfer - correctly & fails with invalid `to` address", async () => {
    const { Vault, BorrowAsset, accounts: [admin,  bob]} = vars
    await initializeVault(Vault, admin)
    // set balance
    await BorrowAsset.setBalanceTo(admin.address, amountToDeposit);
    // approve Vault to take 100
    await BorrowAsset.approve(Vault.address, amountToDeposit);
    await Vault.deposit(BorrowAsset.address, admin.address, admin.address, amountToDeposit)

    await expect(
      Vault.transfer(
        BorrowAsset.address,
        admin.address,
        ethers.constants.AddressZero,
        sharesToTransfer
      )
    ).to.be.revertedWith("INVALID_TO_ADDRESS");

    const currentBalance = (
      await Vault.balanceOf(BorrowAsset.address, admin.address)
    ).toNumber();
    const remainingShareBalance = currentBalance - sharesToTransfer;
    const currentTotal = (await Vault.totals(BorrowAsset.address)).toNumber();

    expect(await Vault.transfer(BorrowAsset.address, admin.address, bob.address, sharesToTransfer))
      .to.emit(Vault, "Transfer")
      .withArgs(BorrowAsset.address, admin.address, bob.address, sharesToTransfer);

    expect(
      await (await Vault.balanceOf(BorrowAsset.address, admin.address)).toNumber()
    ).eq(remainingShareBalance);

    expect(
      await (await Vault.balanceOf(BorrowAsset.address, bob.address)).toNumber()
    ).eq(sharesToTransfer);

    expect((await Vault.totals(BorrowAsset.address)).toNumber()).eq(
      currentTotal
    );
  });

  it("maxFlashLoan", async () => {
    const { Vault, BorrowAsset } = vars
    const currentTotals = (
      await Vault.totals(BorrowAsset.address)
    ).toNumber();
    expect(
      await (await Vault.maxFlashLoan(BorrowAsset.address)).toNumber()
    ).eq(currentTotals);
  });

  it("flashFee", async () => {
    const { Vault, BorrowAsset, accounts: [admin] } = vars
    await initializeVault(Vault, admin)

    const amountToFlashLoan = await Vault.totals(BorrowAsset.address);
    const expectedFlashFee = flashLoanRate.mul(amountToFlashLoan).div(BASE);

    expect(
      await (
        await Vault.flashFee(BorrowAsset.address, amountToFlashLoan)
      ).toNumber()
    ).eq(expectedFlashFee.toNumber());

  });

  it("flashLoan - correctly", async () => {
    const { Vault, BorrowAsset, FlashBorrower, accounts: [admin] } = vars
    await initializeVault(Vault, admin)

    // should revert if not enough balance
    await expect(
      Vault.flashLoan(
        FlashBorrower.address,
        BorrowAsset.address,
        1000,
        "0x"
      )
    ).to.reverted;

    // deposit money to for FlashBorrower
    await setupAccountBalance(BorrowAsset, [admin.address, FlashBorrower.address])
    // admin approve vault to withdraw
    await BorrowAsset.approve(Vault.address, amountToDeposit);
    await Vault.deposit(BorrowAsset.address, admin.address, admin.address, amountToDeposit)

    // call borrow on flashBorrower
    // approve balance
    const amountToFlashLoan = amountToDeposit;
    const expectedFlashFee = flashLoanRate.mul(amountToFlashLoan).div(BASE);

    await BorrowAsset.approve(
      Vault.address,
      amountToDeposit + expectedFlashFee.toNumber()
    );

    // should revert if the user does not pay fee or correct amount
    await expect(
      Vault.flashLoan(
        FlashBorrower.address,
        BorrowAsset.address,
        amountToFlashLoan,
        "0x"
      )
    ).to.reverted;
    
    const data = ethers.utils.defaultAbiCoder.encode(['bool'], [true])

    await expect(
      await Vault.flashLoan(
        FlashBorrower.address,
        BorrowAsset.address,
        amountToFlashLoan,
        data
      )
    )
      .to.emit(Vault, "FlashLoan")
      .withArgs(
        admin.address,
        BorrowAsset.address,
        amountToFlashLoan,
        expectedFlashFee,
        FlashBorrower.address
      );
  });

  it("withdraw fails with invalid `to` address", async  () => {
    const { Vault, BorrowAsset, accounts: [admin] } = vars
    await setupAccountBalanceAndVaultDeposit(Vault, BorrowAsset, [admin])
    await expect(
      Vault.withdraw(
        BorrowAsset.address,
        admin.address,
        ethers.constants.AddressZero,
        amountToDeposit
      )
    ).to.be.revertedWith("INVALID_TO_ADDRESS");
  });

  it("user cannot withdraw more than balance", async () => {
    const { Vault, BorrowAsset, accounts: [admin] } = vars
    await setupAccountBalanceAndVaultDeposit(Vault, BorrowAsset, [admin])
    await expect(
      Vault.withdraw(BorrowAsset.address, admin.address, admin.address, amountToDeposit * 7)
    ).to.be.reverted;
  });

  it("withdraw - correctly", async () => {
    const { Vault, BorrowAsset, accounts: [admin] } = vars
    await setupAccountBalanceAndVaultDeposit(Vault, BorrowAsset, [admin])

    const currentTotals = (
      await Vault.totals(BorrowAsset.address)
    ).toNumber();
    const currentBalance = (
      await Vault.balanceOf(BorrowAsset.address, admin.address)
    ).toNumber();

    const expectedAmountOut = await Vault.toUnderlying(
      BorrowAsset.address,
      currentBalance
    );
    await expect(
      Vault.withdraw(BorrowAsset.address, admin.address, admin.address, currentBalance)
    )
      .to.emit(Vault, "Withdraw")
      .withArgs(
        BorrowAsset.address,
        admin.address,
        admin.address,
        currentBalance,
        expectedAmountOut.toNumber()
      );

    expect(
      await (await Vault.balanceOf(BorrowAsset.address, admin.address)).toNumber()
    ).eq(0);

    expect((await Vault.totals(BorrowAsset.address)).toNumber()).eq(
      currentTotals - currentBalance
    );
  });

  it("updateFlashloanRate", async () => {
    const { Vault, BorrowAsset, accounts: [admin, bob] } = vars
    await initializeVault(Vault, admin)

    const newFlashLoanRate = ethers.utils.parseUnits("0.05", 18);
    await expect(
      Vault.connect(bob.signer).updateFlashloanRate(newFlashLoanRate)
    ).to.be.revertedWith("ONLY_OWNER");

    await Vault.updateFlashloanRate(newFlashLoanRate);
    expect(await Vault.flashLoanRate()).to.eq(newFlashLoanRate);
  });

  it("transferToNewOwner & acceptOwnership", async () => {
    const { Vault, accounts: [admin, bob, alice] } = vars
    await initializeVault(Vault, admin)

    await expect(
      Vault.connect(bob.signer).transferToNewOwner(alice.address)
    ).to.be.revertedWith("ONLY_OWNER");

    await expect(
      Vault.transferToNewOwner(ethers.constants.AddressZero)
    ).to.be.revertedWith("INVALID_NEW_OWNER");
    
    await expect(
      Vault.transferToNewOwner(alice.address)
    ).to.emit(Vault, 'TransferControl');

    expect(await Vault.newOwner()).to.eq(alice.address);
    expect(await Vault.owner()).to.eq(admin.address)

    // alice accepts ownership
    await expect(
      Vault.connect(alice.signer).acceptOwnership()
    ).to.emit(Vault, 'OwnershipAccepted')

    expect(await Vault.newOwner()).to.eq(ethers.constants.AddressZero);
    expect(await Vault.owner()).to.eq(alice.address)
  });

  it("toShare/toUnderlying - convert to appropriate shares & underlying", async () => {
    const { Vault, BorrowAsset, accounts: [admin, bob, alice] } = vars

    const adminAmountToDeposit = 1000
    await setupAccountBalanceAndVaultDeposit(Vault, BorrowAsset, [admin], adminAmountToDeposit)
    const adminShare = (await Vault.balanceOf(BorrowAsset.address, admin.address)).toNumber()
    expect(adminShare).to.eq(adminAmountToDeposit)

    // increase the amount of Vault underlying to 5000
    const amountToIncrease = 4000
    await BorrowAsset.setBalanceTo(Vault.address, amountToIncrease)

    // check the underlying value for the shares minted it should be
    // equal to amountToIncrease + increase in underlying balance
    const newValue = await (await Vault.toUnderlying(BorrowAsset.address, adminAmountToDeposit)).toNumber()
    expect(newValue).to.eq(amountToIncrease + adminAmountToDeposit)
    
    // a new user bob deposits 1000
    await setupAccountBalanceAndVaultDeposit(Vault, BorrowAsset, [bob], adminAmountToDeposit)

    // 1000 * 1000 / 5000 = 200 
    const bobShare = (await Vault.balanceOf(BorrowAsset.address, bob.address)).toNumber()
    expect(bobShare).to.eq(200)
    
    // increase underlying of vault by 11
    await BorrowAsset.setBalanceTo(Vault.address, 11)

    /// a new user alice deposits
    const aliceAmountToDeposit = 300
    await setupAccountBalanceAndVaultDeposit(Vault, BorrowAsset, [alice], aliceAmountToDeposit)
    // 300 * 1200 / 6011 = 59.89
    const aliceShare = (await Vault.balanceOf(BorrowAsset.address, alice.address)).toNumber()
    expect(aliceShare).to.eq(59)
  })

    // const computationalLimit = ethers.BigNumber.from(2).pow(256).sub(1)
    // it("extreme limits", async function() {
    // })

});
