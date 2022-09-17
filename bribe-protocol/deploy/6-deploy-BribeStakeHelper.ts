import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import deployParameters from '../helper/constants';
import { ContractId } from '../helper/types';
import { getBidAssetDeployment } from "../helper/contracts";

const deployBribeStakeHelper: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const {
        deployments: { deploy, get },
        getNamedAccounts,
    } = hre;
    const { deployer } = await getNamedAccounts();

    const bribeToken = await get(ContractId.BribeToken)

    await deploy(ContractId.BribeStakeHelper, {
        from: deployer,
        log: true,
        args: [bribeToken.address]
    })
}

export default deployBribeStakeHelper;
deployBribeStakeHelper.tags = [ContractId.BribeStakeHelper];
