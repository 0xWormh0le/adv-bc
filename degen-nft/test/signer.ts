import { ethers } from 'hardhat'
import { ecsign } from 'ethereumjs-util'

const { keccak256, solidityPack } = ethers.utils

module.exports.sign = (
  privateKey: string,
  score: number,
  character: number,
  ...attrNames: string[]
) => {
  const msg = keccak256(
    attrNames.reduce(
      (prev: string, current: string) => solidityPack(
        ['bytes', 'string'],
        [prev, current]
      ),
      solidityPack(
        ['uint256', 'uint256'],
        [score, character]
      )
    )
  )

  return ecsign(
    Buffer.from(msg.slice(2), 'hex'),
    Buffer.from(privateKey.slice(2), 'hex')
  )
}

module.exports.privateKey = (index: number) => {
  const mnemonic = 'test test test test test test test test test test test junk';
  return ethers.Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/${index}`).privateKey;
}
