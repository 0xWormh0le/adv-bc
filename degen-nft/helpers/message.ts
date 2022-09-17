import { BigNumber, ethers, utils } from 'ethers'
import { IApproveMessageData, IAssetDetails } from './types'
import { ecsign } from "ethereumjs-util"

const { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack } = utils

const NFT_PURCHASE_TYPEHASH = keccak256(
	toUtf8Bytes('NftPurchaseApproval(address user,uint tier,uint score,uint256 nonce)')
)

export function getDomainSeparator(name: string, version: string, tokenAddress: string, chainId: number) {
	return keccak256(
		defaultAbiCoder.encode(
			['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
			[
				keccak256(
					toUtf8Bytes(
						'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
					)
				),
				keccak256(toUtf8Bytes(name)),
				keccak256(toUtf8Bytes(version)),
				chainId,
				tokenAddress
			]
		)
	)
}

export function getDegenMainSignPurchaseMessage(degenMainDetails: IAssetDetails, data: IApproveMessageData) {
	const DOMAIN_SEPARATOR = getDomainSeparator(degenMainDetails.name, degenMainDetails.version, degenMainDetails.address, degenMainDetails.chainId)
    return keccak256(
		solidityPack(
			['bytes1', 'bytes1', 'bytes32', 'bytes32'],
			[
				'0x19',
				'0x01',
				DOMAIN_SEPARATOR,
				keccak256(
					defaultAbiCoder.encode(
						['bytes32', 'address', 'uint256', 'uint256', 'uint256'],
						[NFT_PURCHASE_TYPEHASH, data.user, data.tier, data.score, data.nonce]
					)
				)
			]
		)
	)
}

export async function signDegenMainPurchaseMessage(
    privateKey: string,
    degenMainDetails: IAssetDetails, 
    messageData: IApproveMessageData
): Promise<{ v: number, r: Buffer, s: Buffer }> {
    const data = getDegenMainSignPurchaseMessage(degenMainDetails, messageData)

    const { v, r, s } = ecsign(
        Buffer.from(data.slice(2), 'hex'),
        Buffer.from(privateKey.slice(2), 'hex')
    )

    return { v, r, s }
}
