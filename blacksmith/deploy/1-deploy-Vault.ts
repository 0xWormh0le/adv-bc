import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import { ContractId } from "../helpers/types"
import { UUPSProxy } from '../types';
import { deployAndInitUUPSProxy } from '../helpers/contracts';

const deployVault: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments: { deploy, get }, getNamedAccounts, ethers } = hre;
  const { deployer, blackSmithTeam } = await getNamedAccounts();
  const vaultTx = await deploy(ContractId.Vault, {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: true
  });

  // initialize vault proxy
  if (process.env.WITH_PROXY) await deployAndInitUUPSProxy(
    ContractId.VaultProxy,
    vaultTx.address
    )

};

export default deployVault
deployVault.tags = [ContractId.Vault]
