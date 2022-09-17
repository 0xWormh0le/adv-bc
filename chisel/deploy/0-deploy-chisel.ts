import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployChisel: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { deployer } = await getNamedAccounts();

  await deploy("Chisel", {
    from: deployer,
    args: [],
    log: true,
  });
};

export default deployChisel;
deployChisel.tags = ["Chisel"];
