import hre, { ethers } from 'hardhat';
import { BigNumber, Signer } from 'ethers';
import { EthereumAddress } from './types';
import { ContractReceipt, ContractTransaction } from '@ethersproject/contracts';
import { Result } from '@ethersproject/abi';

export const privateKey = (index: number) => {
  const mnemonic = 'test test test test test test test test test test test junk';
  return ethers.Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/${index}`).privateKey;
};

export const eventArgs = async (
  fn: Promise<ContractTransaction>,
  event: string
): Promise<Result> => {
  const tx: ContractTransaction = await fn;
  const res: ContractReceipt = await tx.wait();
  const evt = res.events?.filter((e) => e.event === event);

  if (evt && evt.length && evt[0].args) {
    return evt[0].args;
  } else {
    return [];
  }
};

export const advanceBlock = async () => ethers.provider.send('evm_mine', []);

export const advanceBlockTo = async (blockNumber: number) => {
  for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
    await advanceBlock();
  }
};
export const expandTo18Decimals = (n: number): BigNumber =>
  BigNumber.from(n).mul(BigNumber.from(10).pow(18));

export const impersonatedAction = async (
  userAddr: EthereumAddress,
  action: (signer: Signer) => void
) => {
  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [userAddr],
  });
  const signer = await ethers.getSigner(userAddr);

  await action(signer);

  await hre.network.provider.request({
    method: 'hardhat_stopImpersonatingAccount',
    params: [userAddr],
  });
};
