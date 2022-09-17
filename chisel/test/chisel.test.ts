import { expect } from 'chai';
import { ethers } from 'hardhat';

import { expandTo18Decimals } from '../helpers/utils';
import { runTestSuite } from '../helpers/lib';
import { deployMockERC20 } from '../helpers/contracts';
import { TestVars } from '../helpers/types';

runTestSuite('Chisel', (vars: TestVars) => {
  it('initialize', async () => {
    const {
      Chisel,
      Vault,
      BaseTokenMock,
      accounts: [alice],
      initializedEventArgs,
    } = vars;
    const [admin, vault, baseToken] = initializedEventArgs;

    expect(admin).to.equal(alice.address);
    expect(vault).to.equal(Vault.address);
    expect(baseToken).to.equal(BaseTokenMock.address);

    expect(await Chisel.admin()).to.equal(alice.address);
    expect(await Chisel.vault()).to.equal(Vault.address);
    expect(await Chisel.baseToken()).to.equal(BaseTokenMock.address);
  });

  describe('deposit: ', async () => {
    const depositAmount = 100;

    it('should success: deposit with tokens', async () => {
      const {
        Chisel,
        accounts: [alice],
      } = vars;

      // deposit with tokens
      await expect(Chisel.connect(alice.signer).deposit(depositAmount, false))
        .to.emit(Chisel, 'Deposited')
        .withArgs(alice.address, depositAmount, false);

      expect(await Chisel.balanceOf(alice.address)).to.equal(depositAmount);
    });

    it('should success: deposit with vault shares', async () => {
      const {
        Chisel,
        BaseTokenMock,
        Vault,
        accounts: [alice],
      } = vars;

      // vault share
      await Vault.connect(alice.signer).deposit(
        BaseTokenMock.address,
        alice.address,
        alice.address,
        depositAmount
      );
      await expect(Chisel.connect(alice.signer).deposit(depositAmount, true))
        .to.emit(Chisel, 'Deposited')
        .withArgs(alice.address, depositAmount, true);

      expect(await Chisel.balanceOf(alice.address)).to.equal(depositAmount);
    });

    it('should fail: deposit', async () => {
      const {
        Chisel,
        BaseTokenMock,
        Vault,
        accounts: [, , carl],
      } = vars;

      await expect(Chisel.connect(carl.signer).deposit(100, true)).to.be.revertedWith(
        'ONLY_ALLOWED'
      );

      await expect(Chisel.connect(carl.signer).deposit(100, false)).to.be.revertedWith(
        'ONLY_ALLOWED'
      );
    });
  });

  describe('withdraw', () => {
    it('should fail: when pair does not match', async () => {
      const {
        Chisel,
        LendingPairMock,
        accounts: [alice],
      } = vars;

      // set different asset from Chisel's base token
      const asset = await deployMockERC20();
      await LendingPairMock.connect(alice.signer).mockInitialize(
        asset.address,
        ethers.constants.AddressZero
      );
      await expect(
        Chisel.connect(alice.signer).withdraw(LendingPairMock.address, 0, alice.address)
      ).to.revertedWith('Incorrect Pair');
    });

    it('should fail: when withdraw amount exceeds receipt token balance', async () => {
      const {
        Chisel,
        LendingPairMock,
        accounts: [alice],
      } = vars;
      await expect(
        Chisel.connect(alice.signer).withdraw(LendingPairMock.address, 100, alice.address)
      ).to.revertedWith('withdraw: Exceed');
    });

    it('should success: balance becomes bigger after withdraw', async () => {
      const {
        Chisel,
        BaseTokenMock,
        LendingPairMock,
        accounts: [alice],
      } = vars;
      const withdrawAmount = 50;

      await Chisel.connect(alice.signer).deposit(100, false);
      const prevBalance = await BaseTokenMock.balanceOf(alice.address);

      await expect(
        Chisel.connect(alice.signer).withdraw(
          LendingPairMock.address,
          withdrawAmount,
          alice.address
        )
      )
        .to.emit(Chisel, 'Withdraw')
        .withArgs(LendingPairMock.address, withdrawAmount, alice.address);

      const afterBalance = await BaseTokenMock.balanceOf(alice.address);
      expect(afterBalance.sub(prevBalance).toNumber()).to.equal(withdrawAmount);
    });
  });

  describe('Chilsel admin scenario', async () => {
    it('should failed: no admin permissions', async () => {
      const {
        Chisel,
        LendingPairMock,
        accounts: [, bob],
      } = vars;

      // call addLiquidityToPair() without admin persmion
      await expect(
        Chisel.connect(bob.signer).addLiquidityToPair(LendingPairMock.address, 0)
      ).to.revertedWith('Not Admin');

      // call setCallIncentive() without admin persmion
      await expect(Chisel.connect(bob.signer).setCallIncentive(0)).to.revertedWith('Not Admin');

      // call rebalance() without admin persmion
      await expect(
        Chisel.connect(bob.signer).rebalance(LendingPairMock.address, LendingPairMock.address, 0)
      ).to.revertedWith('Not Admin');
    });

    it('should success: check liquidity update after addLiquidityToPair', async () => {
      const {
        Chisel,
        Vault,
        BaseTokenMock,
        LendingPairMock,
        accounts: [admin],
      } = vars;

      const liquidityAmount = 50;
      await Chisel.connect(admin.signer).deposit(100, false);

      const prevBalance = await (
        await Vault.balanceOf(BaseTokenMock.address, LendingPairMock.address)
      ).toNumber();

      await expect(
        Chisel.connect(admin.signer).addLiquidityToPair(LendingPairMock.address, liquidityAmount)
      )
        .to.emit(Chisel, 'LiquidityAdded')
        .withArgs(LendingPairMock.address, liquidityAmount);

      const afterBalance = (
        await Vault.balanceOf(BaseTokenMock.address, LendingPairMock.address)
      ).toNumber();

      expect(afterBalance - prevBalance).to.equal(liquidityAmount);
    });

    it('should success: check liquidity update after rebalance', async () => {
      const {
        Chisel,
        Vault,
        BaseTokenMock,
        LendingPairMock,
        SecondLendingPairMock,
        accounts: [alice],
      } = vars;

      await Chisel.connect(alice.signer).deposit(100, false);

      // test data
      const lendingPairFundedLiquidity = 10;
      const rebalanceAmount = await Vault.toShare(BaseTokenMock.address, 5, false);

      await Chisel.connect(alice.signer).addLiquidityToPair(
        LendingPairMock.address,
        lendingPairFundedLiquidity
      );
      await Chisel.connect(alice.signer).addLiquidityToPair(
        SecondLendingPairMock.address,
        lendingPairFundedLiquidity
      );

      const prevPair1Liquidity = (
        await Vault.balanceOf(BaseTokenMock.address, LendingPairMock.address)
      ).toNumber();
      const prevPair2Liquidity = (
        await Vault.balanceOf(BaseTokenMock.address, SecondLendingPairMock.address)
      ).toNumber();

      await Chisel.connect(alice.signer).rebalance(
        LendingPairMock.address,
        SecondLendingPairMock.address,
        rebalanceAmount
      );

      const afterPair1Liquidity = (
        await Vault.balanceOf(BaseTokenMock.address, LendingPairMock.address)
      ).toNumber();
      const afterPair2Liquidity = (
        await Vault.balanceOf(BaseTokenMock.address, SecondLendingPairMock.address)
      ).toNumber();

      await expect(prevPair1Liquidity - afterPair1Liquidity).to.equal(rebalanceAmount.toNumber());
      await expect(afterPair2Liquidity - prevPair2Liquidity).to.equal(rebalanceAmount.toNumber());
    });

    it('should success: setCallIncentive', async () => {
      const { Chisel } = vars;

      await expect(Chisel.setCallIncentive(123))
        .to.emit(Chisel, 'NewCallIncentiveSet')
        .withArgs(123);
    });
  });

  describe('distributeIncome & interests', async () => {
    it('distributeIncome', async () => {
      const {
        Chisel,
        Vault,
        BaseTokenMock,
        LendingPairMock,
        accounts: [alice, bob],
      } = vars;
      // deposit
      await Chisel.connect(alice.signer).deposit(expandTo18Decimals(100), false);
      await Chisel.connect(alice.signer).addLiquidityToPair(
        LendingPairMock.address,
        await Vault.toShare(BaseTokenMock.address, expandTo18Decimals(100), false)
      );

      const beforeBalance = await BaseTokenMock.balanceOf(bob.address);

      await Chisel.connect(bob.signer).distributeIncome(LendingPairMock.address);

      const afterBalance = await BaseTokenMock.balanceOf(bob.address);
      const rewards = afterBalance.sub(beforeBalance);
      expect(Number(rewards._hex)).to.greaterThan(Number(0));
    });

    it('interest', async () => {
      const {
        Chisel,
        Vault,
        BaseTokenMock,
        LendingPairMock,
        accounts: [alice, bob, carl],
      } = vars;

      // deposit
      await Chisel.connect(alice.signer).deposit(expandTo18Decimals(100), false);
      await Chisel.connect(bob.signer).deposit(expandTo18Decimals(100), false);
      await Chisel.connect(alice.signer).addLiquidityToPair(
        LendingPairMock.address,
        await Vault.toShare(BaseTokenMock.address, expandTo18Decimals(200), false)
      );

      // call distribute Income
      await Chisel.connect(carl.signer).distributeIncome(LendingPairMock.address);
      await Chisel.connect(bob.signer).withdraw(LendingPairMock.address, 0, bob.address);

      // rewards
      const rewards = await Chisel.balanceOf(bob.address);
      expect(Number(rewards._hex)).to.greaterThan(Number(0));
    });
  });
});
