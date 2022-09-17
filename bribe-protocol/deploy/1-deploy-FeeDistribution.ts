import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import deployParameters from '../helper/constants';
import { ContractId, PoolInfo } from '../helper/types';
import { getBidAssetDeployment } from "../helper/contracts";

const deployFeeDistribution: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const {
        deployments: { deploy, get },
        getNamedAccounts,
        getChainId,
    } = hre;

    const { deployer } = await getNamedAccounts();
    const currentDeployParameters = deployParameters[hre.network.name];

    const bidAsset  = await getBidAssetDeployment(
        currentDeployParameters.bidAsset
    )

    for(let i = 0; i < PoolInfo.length; i++ ) {
        const poolInfo = PoolInfo[i]

        await deploy(`${ContractId.FeeDistribution}${poolInfo[0]}`, {
            from: deployer,
            contract: ContractId.FeeDistribution,
            log: true,
            args: [bidAsset.address]
        })
    }
    
}

export default deployFeeDistribution;
deployFeeDistribution.tags = [ContractId.FeeDistribution];