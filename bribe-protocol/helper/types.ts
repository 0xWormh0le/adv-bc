export enum ContractId {
  AavePool = "AavePool",
  USDC = "USDC",
  Erc20 = "Erc20",
  FeeDistribution = "FeeDistribution",
  BribeToken = "BribeToken",
  Dividend = "Dividends",
  FeeToken = "FeeToken",
  BidAsset = "BidAsset",
  Aave = "MockAave",
  StkAave = "MockStkAave",
  MockAaveGovernanceWithTokens = "MockAaveGovernanceWithTokens",
  MockPool = "MockPool",
  StkAaveWrapperToken = "StkAaveWrapperToken",
  AaveWrapperToken = "AaveWrapperToken",
  BribeStakeHelper = "BribeStakeHelper",
  AaveMIMBidHelperV1 = "AaveMIMBidHelperV1",
  MockFeeDistributor = "MockFeeDistributor",
}

export const PoolInfo = [
  // pool name, pool governance token symbol
  ["AavePool", "Aave"],
];

export type EthereumAddress = string;
