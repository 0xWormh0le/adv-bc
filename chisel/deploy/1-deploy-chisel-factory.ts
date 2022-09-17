import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployChiselFactory: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy, get },
    getNamedAccounts,
  } = hre;
  const { deployer, admin } = await getNamedAccounts();

  const chiselImpl = await get('Chisel');

  await deploy('ChiselFactory', {
    from: deployer,
    args: [chiselImpl.address, admin],
    log: true,
  });
};

export default deployChiselFactory;
deployChiselFactory.tags = ['ChiselFactory'];
