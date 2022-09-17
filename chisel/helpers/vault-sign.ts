import hre, { ethers } from 'hardhat'
import { Signer } from 'ethers';
import { Contract } from '@ethersproject/contracts';
import { ecsign } from 'ethereumjs-util'
import { IAccount, EthereumAddress, IAssetDetails, IApproveMessageData } from './types'


const { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack } = ethers.utils

const VAULT_APPROVAL_TYPEHASH = keccak256(
	toUtf8Bytes('VaultAccessApproval(bytes32 warning,address user,address contract,bool approved,uint256 nonce)')
)

const getDomainSeparator = (
  name: string,
  version: string,
  tokenAddress: string,
  chainId: number
) => keccak256(
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

const getVaultSignApproveContractMessage = (
  vaultDetails: IAssetDetails,
  data: IApproveMessageData
) => {
	const DOMAIN_SEPARATOR = getDomainSeparator(
    vaultDetails.name,
    vaultDetails.version,
    vaultDetails.address,
    vaultDetails.chainId
  )
  const warning = data.approve
    ? keccak256(toUtf8Bytes(`Grant full access to funds in Warp Vault? Read more here https://warp.finance/permission`))
    : keccak256(toUtf8Bytes(`Revoke access to Warp Vault? Read more here https://warp.finance/revoke`))

  return keccak256(
    solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      [
        '0x19',
        '0x01',
        DOMAIN_SEPARATOR,
        keccak256(
          defaultAbiCoder.encode(
            ['bytes32', 'bytes32', 'address', 'address', 'bool', 'uint256'],
            [VAULT_APPROVAL_TYPEHASH, warning, data.user, data.contract, data.approve, data.nonce]
          )
        )
      ]
    )
	)
}

const signVaultApproveContractMessage = async (
  privateKey: string,
  vaultDetails: IAssetDetails, 
  messageData: IApproveMessageData
): Promise<{ v: number, r: Buffer, s: Buffer }> => {
  const data = getVaultSignApproveContractMessage(vaultDetails, messageData)
  const { v, r, s } = ecsign(
    Buffer.from(data.slice(2), 'hex'),
    Buffer.from(privateKey.slice(2), 'hex')
  )
  return { v, r, s }
}

const getVaultDetails = async (vault: Contract) => ({
  name: await vault.name(),
  address: vault.address,
  chainId: (await ethers.provider.getNetwork()).chainId,
  version: await vault.version()
})

const approveInVaultMessage = async (
  vault: Contract,
  account: IAccount,
  addressToApprove: EthereumAddress,
  approve: boolean
) => {
  const vaultDetails = await getVaultDetails(vault)
  const nonce = (await vault.userApprovalNonce(account.address)).toNumber()
  return await signVaultApproveContractMessage(
    account.privateKey,
    vaultDetails,
    {
      approve,
      user: account.address,
      nonce,
      contract: addressToApprove
    }
  )
}

export const approveInVault = async (
  vault: Contract,
  account: IAccount,
  addressToApprove: EthereumAddress,
  approve: boolean
) => {
  const { v, r, s } = await approveInVaultMessage(vault, account, addressToApprove, approve)
  return await vault.connect(account.signer).approveContract(
    account.address,
    addressToApprove,
    approve,
    v,
    r,
    s
  )
}
