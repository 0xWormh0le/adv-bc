export enum ContractId {
    Vault = 'Vault',
    MockToken = 'MockToken',
    LendingPair = 'LendingPair',
    LendingPairFactory = 'LendingPairFactory',
    Control = 'Control',
    WrapperToken = 'BorrowWrapperToken',
    UUPSProxy = 'UUPSProxy',
    MockFlashBorrower = 'MockFlashBorrower',
    MockLendingPair = 'MockLendingPair',
    UUPSProxiable = 'UUPSProxiable',
    MockPriceOracle  = 'MockPriceOracle',
    JumpRateModelV2 = 'JumpRateModelV2',
    PriceOracleAggregator = 'PriceOracleAggregator',
    MockVault = 'MockVault',
    DataTypes = 'DataTypes',
    LendingPairHelper = 'LendingPairHelper',
    DebtToken = 'DebtToken',
    CollateralWrapperToken = 'CollateralWrapperToken',
    MockChainlinkUSDAdapter = 'MockChainlinkUSDAdapter',
    VaultStorageLayoutTester = 'VaultStorageLayoutTester',
    SafeERC20 = 'SafeERC20',
    VaultFactory = 'VaultFactory',
    RewardDistributorManager = 'RewardDistributorManager',
    RewardDistributor = 'RewardDistributor',
    RewardDistributorFactory = 'RewardDistributorFactory',
    MockDistributorManager = 'MockRewardDistributorManager',
    FeeWithdrawal = 'FeeWithdrawal',
    MockUniswapV2Router02 = 'MockUniswapV2Router02',
    VaultProxy = 'VaultProxy',
    FeeWithdrawalProxy = 'FeeWithdrawalProxy',
    PriceOracleAggregatorProxy = 'PriceOracleAggregatorProxy',
    RewardDistributorManagerProxy = 'RewardDistributorManagerProxy'
}

export enum LendingPairWarpActions {
    COLLATERAL_DEPOSIT = 1,
    BORROW_ASSET_DEPOSIT = 2,
    REPAY = 3,
    REDEEM = 4,
    WITHDRAW_COLLATERAL = 5,
    VAULT_DEPOSIT = 6,
    VAULT_WITHDRAW = 7,
    VAULT_TRANSFER = 8,
    VAULT_APPROVE_CONTRACT = 9
}

export interface IAssetDetails {
    name: string,
    version: string,
    address: EthereumAddress,
    chainId: number
}

export interface IApproveMessageData {
    nonce: number,
    approve: boolean,
    user: EthereumAddress,
    contract: EthereumAddress
}

export interface IDelegateBorrowMessageData {
    from: EthereumAddress,
    to: EthereumAddress,
    amount: number,
    nonce: number
}

export enum LendingPairActions {
    Deposit = 0,
    Borrow = 1,
}

export type EthereumAddress = string;
