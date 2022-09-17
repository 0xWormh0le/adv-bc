import hre, { deployments, ethers } from 'hardhat';
import { Signer, Contract, Wallet, BigNumber } from 'ethers';
import { assert } from 'chai';
import { Result } from '@ethersproject/abi';

import {
  getChiselDeployment,
  getChiselFactoryDeployment,
  getVaultDeployment,
  deployMockERC20,
  deployLendingPairMock,
  deployVaultMock,
} from './contracts';
import { Chisel, ChiselFactory, MockERC20, LendingPairMock, VaultMock } from '../types';
import { eventArgs, expandTo18Decimals, impersonatedAction, privateKey } from './utils';
import { approveInVault } from './vault-sign';
import { TestVars } from './types';

const testVars: TestVars = {
  accounts: [],
  namedAccounts: {},

  // contracts
  Chisel: {} as Chisel,
  ChiselFactory: {} as ChiselFactory,
  Vault: {} as Contract,

  // mocks
  BaseTokenMock: {} as MockERC20,
  LendingPairMock: {} as LendingPairMock,
  SecondLendingPairMock: {} as LendingPairMock,

  // other
  isForked: false,
  initializedEventArgs: {} as Result,
};

const deployTestTokensAndMock = async () => ({
  BaseTokenMock: await deployMockERC20(),
  LendingPairMock: await deployLendingPairMock(),
  SecondLendingPairMock: await deployLendingPairMock(),
});

const getVault = async (isForked: boolean) => {
  if (isForked) {
    return await getVaultDeployment();
  } else {
    return await deployVaultMock();
  }
};

const makeChiselTestSuiteVars = async (vars: TestVars) => {
  const Chisel = await getChiselDeployment();
  const ChiselFactory = await getChiselFactoryDeployment();
  const isForked = hre.config.networks.hardhat.forking?.enabled;
  let Vault = await getVault(isForked || false);

  const { BaseTokenMock, LendingPairMock, SecondLendingPairMock, accounts } = vars;

  const [admin] = accounts;
  const initializedEventArgs = await eventArgs(
    Chisel.connect(admin.signer).initialize(admin.address, Vault.address, BaseTokenMock.address),
    'Initialized'
  );

  if (isForked) {
    const vaultOwnerAddr = await Vault.owner();
    await impersonatedAction(vaultOwnerAddr, async (signer) => {
      await Vault.connect(signer).allowContract(Chisel.address, true);
      await Vault.connect(signer).allowContract(LendingPairMock.address, true);
      await Vault.connect(signer).allowContract(SecondLendingPairMock.address, true);
    });
  }

  // init lendingPairs
  await LendingPairMock.connect(admin.signer).mockInitialize(BaseTokenMock.address, Vault.address);
  await SecondLendingPairMock.connect(admin.signer).mockInitialize(
    BaseTokenMock.address,
    Vault.address
  );

  for (let i = 0; i < accounts.length; i++) {
    await BaseTokenMock.connect(accounts[i].signer).mint(
      accounts[i].address,
      expandTo18Decimals(1000)
    );
    await BaseTokenMock.connect(accounts[i].signer).approve(
      Vault.address,
      expandTo18Decimals(1000)
    );
  }

  for (let i = 0; i < 2; i++) {
    // approve & deposit into Vault
    await approveInVault(Vault, accounts[i], Chisel.address, true);
    await Vault.connect(accounts[i].signer).deposit(
      BaseTokenMock.address,
      accounts[i].address,
      accounts[i].address,
      expandTo18Decimals(100)
    );
  }

  return {
    Chisel,
    ChiselFactory,
    Vault,
    initializedEventArgs,
    isForked,
  };
};

export function runTestSuite(title: string, tests: (arg: TestVars) => void) {
  describe(title, function () {
    before(async () => {
      // we manually derive the signers address using the mnemonic
      // defined in the hardhat config

      testVars.accounts = await Promise.all(
        (
          await ethers.getSigners()
        ).map(async (signer, index) => ({
          signer,
          address: await signer.getAddress(),
          privateKey: privateKey(index),
        }))
      );

      const namedAccounts = await ethers.getNamedSigners();
      Object.keys(namedAccounts).forEach(async (key) => {
        testVars.namedAccounts[key] = {
          signer: namedAccounts[key],
          address: await namedAccounts[key].getAddress(),
          privateKey: '',
        };
      });

      assert.equal(
        new Wallet(testVars.accounts[0].privateKey).address,
        testVars.accounts[0].address,
        'invalid mnemonic or address'
      );
    });

    beforeEach(async () => {
      const setupTest = deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const vars = await deployTestTokensAndMock();
        Object.assign(testVars, vars);
      });

      await setupTest();
      const vars = await makeChiselTestSuiteVars(testVars);
      Object.assign(testVars, vars);
    });

    tests(testVars);
  });
}
