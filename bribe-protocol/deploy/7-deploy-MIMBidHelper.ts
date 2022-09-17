import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ContractId } from "../helper/types";
import deployParameters from "../helper/constants";

const deployMIMBidHelper: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy, get },
    getNamedAccounts,
  } = hre;
  const { deployer } = await getNamedAccounts();

  const currentDeployParameters = deployParameters[hre.network.name];

  const aaveBribePool = await get(ContractId.AavePool);

  await deploy(ContractId.AaveMIMBidHelperV1, {
    from: deployer,
    log: true,
    args: [currentDeployParameters.usdc, aaveBribePool.address],
  });
};

export default deployMIMBidHelper;
deployMIMBidHelper.tags = [ContractId.AaveMIMBidHelperV1];
