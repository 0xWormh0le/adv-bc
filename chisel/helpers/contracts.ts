import { deployments, ethers } from 'hardhat';
import { Contract } from 'ethers';
import vault from '../test/abis/vault.json';
import { Chisel, ChiselFactory, MockERC20, LendingPairMock, VaultMock } from '../types';

export enum ContractId {
  // contracts
  Chisel = 'Chisel',
  ChiselFactory = 'ChiselFactory',
  // mocks
  MockERC20 = 'MockERC20',
  LendingPairMock = 'LendingPairMock',
  VaultMock = 'VaultMock',
}

export const deployContract = async <ContractType extends Contract>(
  contractName: string,
  args: any[]
) => {
  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(...args);
  return contract;
};

export const getChiselDeployment = async (): Promise<Chisel> => {
  const deployed = await deployments.get(ContractId.Chisel);
  return await ethers.getContractAt(ContractId.Chisel, deployed.address);
};

export const getChiselFactoryDeployment = async (): Promise<ChiselFactory> => {
  const deployed = await deployments.get(ContractId.ChiselFactory);
  return await ethers.getContractAt(ContractId.ChiselFactory, deployed.address);
};

export const getVaultDeployment = async () => await ethers.getContractAt(vault.abi, vault.address);

export const deployVaultMock = async () =>
  await deployContract<VaultMock>(ContractId.VaultMock, []);

export const deployMockERC20 = async () =>
  await deployContract<MockERC20>(ContractId.MockERC20, ['BTMock', 'BTMock']);

export const deployLendingPairMock = async () =>
  await deployContract<LendingPairMock>(ContractId.LendingPairMock, []);
