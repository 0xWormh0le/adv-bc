export interface IAssetDetails {
    name: string,
    version: string,
    address: EthereumAddress,
    chainId: number
}

export interface IApproveMessageData {
    nonce: number,
    tier: number,
    user: EthereumAddress,
    score: number
}

export type EthereumAddress = string;
