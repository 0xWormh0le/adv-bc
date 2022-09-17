import { Signer, Contract } from 'ethers';
import { Result } from '@ethersproject/abi';

import { Chisel, ChiselFactory, MockERC20, LendingPairMock, VaultMock } from '../types';

export type EthereumAddress = string;

export type IAssetDetails = {
  name: string;
  version: string;
  address: EthereumAddress;
  chainId: number;
};

export type IApproveMessageData = {
  nonce: number;
  approve: boolean;
  user: EthereumAddress;
  contract: EthereumAddress;
};

export interface IAccount {
  signer: Signer;
  address: string;
  privateKey: string;
}

export interface TestVars {
  accounts: IAccount[];
  namedAccounts: { [name: string]: IAccount };

  // contracts
  Chisel: Chisel;
  ChiselFactory: ChiselFactory;
  Vault: Contract | VaultMock;

  // mocks
  BaseTokenMock: MockERC20;
  LendingPairMock: LendingPairMock;
  SecondLendingPairMock: LendingPairMock;

  // other
  isForked: boolean;
  initializedEventArgs: Result;
}
