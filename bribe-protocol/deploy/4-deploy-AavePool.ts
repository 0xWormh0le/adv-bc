import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import deployParameters from "../helper/constants";
import { ContractId } from "../helper/types";
import {
  getAaveDeployment,
  getAaveGovernance,
  getBidAssetDeployment,
  getStkAaveDeployment,
} from "../helper/contracts";

const deployAavePool: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy, get },
    getNamedAccounts,
  } = hre;

  const { deployer } = await getNamedAccounts();

  const bribeToken = await get(ContractId.BribeToken);
  console.log(bribeToken.address);
  const feeDistributor = await get(`${ContractId.FeeDistribution}AavePool`);
  const currentDeployParameters = deployParameters[hre.network.name];
  const bidAsset = await getBidAssetDeployment(currentDeployParameters.bidAsset);
  const aave = await getAaveDeployment(currentDeployParameters.aave);
  const stkAave = await getStkAaveDeployment(currentDeployParameters.stkAave);

  const aaveGovernance = await getAaveGovernance(currentDeployParameters.aaveGovernance);
  const aaveWrapperToken = await get(ContractId.AaveWrapperToken);
  const stkAaveWrapperToken = await get(ContractId.StkAaveWrapperToken);

  await deploy(ContractId.AavePool, {
    from: deployer,
    args: [
      bribeToken.address,
      aave.address,
      stkAave.address,
      bidAsset.address,
      aaveGovernance.address,
      feeDistributor.address,
      aaveWrapperToken.address,
      stkAaveWrapperToken.address,
      [0, 0, 0],
    ],
    log: true,
  });
};

export default deployAavePool;
deployAavePool.tags = [ContractId.AavePool];
