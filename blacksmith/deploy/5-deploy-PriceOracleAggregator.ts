import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import { ContractId, EthereumAddress } from "../helpers/types"
import { deployAndInitUUPSProxy } from '../helpers/contracts';

const deployPriceOracleAggregator: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments: { deploy }, getNamedAccounts } = hre;
  const { deployer, blackSmithTeam } = await getNamedAccounts();
  
  const aggTx = await deploy(ContractId.PriceOracleAggregator, {
    from: deployer,
    args: [blackSmithTeam],
    log: true,
    deterministicDeployment: true
  });

  if (process.env.WITH_PROXY) {
    await deployAndInitUUPSProxy(
      ContractId.PriceOracleAggregatorProxy,
      aggTx.address
    )
    }

};

export default deployPriceOracleAggregator
deployPriceOracleAggregator.tags = [ContractId.PriceOracleAggregator]
