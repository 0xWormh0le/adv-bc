import { ethers, waffle } from "hardhat";
import { expect, assert } from "chai";
import { runTestSuite, setupAndInitLendingPair, TestVars, defaultLendingPairInitVars } from "./lib";
import { LendingPairWarpActions } from "../helpers/types";
import { defaultAbiCoder } from "@ethersproject/abi";

runTestSuite("LendingPair - Warp", (vars: TestVars) => {
    it("warp - actions", async() => {
        const {
            Vault,
            BorrowAsset,
            LendingPair,
            accounts: [admin, bob, frank],
            LendingPairHelper,
            DebtToken
        } = vars
      
        const helper = await setupAndInitLendingPair(
            vars,
            {...defaultLendingPairInitVars, account: admin }      
        )

        const actions = []
        const data = []

        // approve in vault
        const { v, r, s } = await helper.approveInVaultMessage(admin, LendingPair.address, true) 
        const approveContractData = defaultAbiCoder.encode(
            ["address", "address", "bool", "uint8","bytes32", "bytes32"],
            [admin.address, LendingPair.address, true, v, r, s]
        )
        actions.push(LendingPairWarpActions.VAULT_APPROVE_CONTRACT)
        data.push(approveContractData)

        // deposit in vault
        await helper.setAccountBalance(admin.signer, BorrowAsset, 10000)
        const depositVaultData = defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [BorrowAsset.address, admin.address, 10000]
        )
        actions.push(LendingPairWarpActions.VAULT_DEPOSIT)
        data.push(depositVaultData)

        // transfer in vault
        const transferVaultData = defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [BorrowAsset.address, bob.address, 1]
        )
        actions.push(LendingPairWarpActions.VAULT_TRANSFER)
        data.push(transferVaultData)

        // withdraw in vault
        const withdrawData = defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [BorrowAsset.address, bob.address, 100]
        )
        actions.push(LendingPairWarpActions.VAULT_WITHDRAW)
        data.push(withdrawData)

        // 

        await LendingPair.warp(actions, data)        
    })
})