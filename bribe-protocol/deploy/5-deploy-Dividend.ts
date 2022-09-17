import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import deployParameters from '../helper/constants';
import { ContractId, PoolInfo } from '../helper/types';
import { getBidAssetDeployment } from "../helper/contracts";

const deployDividend: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const {
        deployments: { deploy, get },
        getNamedAccounts,
    } = hre;
    const { deployer } = await getNamedAccounts();
    const currentDeployParameters = deployParameters[hre.network.name]

    const rewardAsset = await getBidAssetDeployment(
        currentDeployParameters.bidAsset
    )
    const stakeAsset = await get(ContractId.BribeToken)

    for(let i = 0; i < PoolInfo.length; i++ ) {
        const poolInfo = PoolInfo[i]

        const name = `stkBribe${poolInfo[0]}`
        const symbol = `stkBr${poolInfo[1]}`
        const feeDistributor = await get(`${ContractId.FeeDistribution}${poolInfo[0]}`)
        
        /// artifact name e.g. DividendsAavePool
        await deploy(`${ContractId.Dividend}${poolInfo[0]}`, {
            from: deployer,
            contract: ContractId.Dividend,
            log: true,
            args: [
                rewardAsset.address,
                stakeAsset.address,
                feeDistributor.address,
                name,
                symbol
            ],
            
        })
    }

   
}

export default deployDividend;
deployDividend.tags = [ContractId.Dividend];
