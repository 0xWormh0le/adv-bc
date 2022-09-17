import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

// deploy/1-deploy-DegenMain.ts
const deployDegenMain: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { deployer } = await getNamedAccounts();

  if (process.env.WITH_PROXY) return;

  await deploy("DegenMain", {
    from: deployer,
    args: [],
    log: true,
  });
};

export default deployDegenMain;
deployDegenMain.tags = ["DegenMain"];
