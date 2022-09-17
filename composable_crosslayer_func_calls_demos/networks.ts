import { ethers } from "ethers";

//TODO: utilize evm-chains
require("dotenv").config();

const INFURA_API_KEY = process.env.INFURA_API_KEY;

const PRIVATE_KEY_1 = process.env.PRIVATE_KEY_1;
const PRIVATE_KEY_2 = process.env.PRIVATE_KEY_2;
const PRIVATE_KEY_3 = process.env.PRIVATE_KEY_3;

export type Network = {
  url?: string;
  name?: string;
  accounts: (string | undefined)[] | string;
  network_id?: number | string;
  timeout?: number;
  gas?: number;
  gasPrice?: number;
  chainId?: number;
  confirmations?: number;
};

export const mainnet: Network = {
  url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  network_id: 1,
};
export const kovan: Network = {
  url: `https://kovan.infura.io/v3/${INFURA_API_KEY}`,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const ropsten: Network = {
  url: `https://ropsten.infura.io/v3/${INFURA_API_KEY}`,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  network_id: 3,
};
export const rinkeby: Network = {
  url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  network_id: 4,
  gasPrice: 20000000000,
  gas: 10000000,
};
export const goerli: Network = {
  url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const arbitrum_testnet: Network = {
  url: `https://arb-rinkeby.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
  //network_id: 421611, TODO: solve issue with 2 network configs with the same network_id
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  timeout: 120000,
  gasPrice: 20000000,
  gas: 10000000,
};

export const arbitrum_testnet_pub: Network = {
  url: "https://rinkeby.arbitrum.io/rpc",
  network_id: 421611,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  timeout: 300000,
  gasPrice: 15_000_000,
  gas: 10_000_000,
};

export const arbitrum_testnet_kovan: Network = {
  url: "https://kovan5.arbitrum.io/rpc",
  network_id: 144545313136048,
  gasPrice: 0,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  timeout: 120000,
};
export const arbitrum_mainnet: Network = {
  url: "https://arb1.arbitrum.io/rpc",
  network_id: 42161,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const optimism_l1_local: Network = {
  url: "http://127.0.0.1:9545",
  network_id: "*",
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const optimism_l2_public: Network = {
  url: "https://kovan.optimism.io",
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  timeout: 120000,
};
export const optimism_l2_local: Network = {
  url: "http://127.0.0.1:8545",
  gas: 90000000,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const transfer_optimism: Network = {
  url: "http://127.0.0.1:9545/",
  network_id: "*",
  accounts: "remote",
};
export const matic_mumbai: Network = {
  url: "https://matic-mumbai.chainstacklabs.com",
  network_id: 80001,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  gasPrice: 1000000000,
  gas: 10000000,
};
export const matic_mainnet: Network = {
  //url: "https://polygon-mainnet.infura.io/v3/${INFURA_API_KEY}",
  url: "https://rpc-mainnet.maticvigil.com",
  chainId: 137,
  network_id: 137,
  gas: 6000000,
  // gasPrice: 10000000000,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  timeout: 300000,
  confirmations: 2,
};
export const matic: Network = {
  url: "https://rpc-mainnet.maticvigil.com",
  network_id: 137,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const xdai_sokol: Network = {
  url: "https://sokol.poa.network",
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const xdai_main: Network = {
  url: "https://rpc.xdaichain.com/",
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};

export const avalanche: Network = {
  //mainnet
  url: "https://api.avax.network/ext/bc/C/rpc",
  network_id: 43114,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const avalanche_testnet: Network = {
  //testnet
  url: "https://api.avax-test.network/ext/bc/C/rpc",
  network_id: 43113,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const moonriver_testnet: Network = {
  //testnet
  url: "https://rpc.testnet.moonbeam.network",
  network_id: 1287,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};
export const moonriver: Network = {
  url: "https://rpc.moonriver.moonbeam.network",
  network_id: 1285,
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};

export const hardhat: Network = {
  url: "",
  accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
};

const networks = {
  mainnet,
  kovan,
  ropsten,
  rinkeby,
  goerli,
  arbitrum_testnet,
  arbitrum_testnet_pub,
  arbitrum_testnet_kovan,
  arbitrum_mainnet,
  optimism_l1_local,
  optimism_l2_public,
  optimism_l2_local,
  transfer_optimism,
  matic_mumbai,
  matic,
  xdai_sokol,
  xdai_main,
  avalanche,
  avalanche_testnet,
  moonriver_testnet,
  moonriver,
  matic_mainnet,
};

export function getNetworkObjFromId(networkId: number | string): Network {
  let returnNetwork: Network;
  if (typeof networkId == "string") {
    if (networkId == "") returnNetwork = Object(networks)["hardhat"];
    else returnNetwork = Object(networks)[networkId];
  } else {
    // returnNetwork = Object(networks).find((n: Network ) => n.network_id && n.network_id == networkId);
    returnNetwork = Object.values(networks).find(
      (n: Network) => n.network_id && n.network_id === networkId
    )!;
    if (returnNetwork) {
      const result = Object.entries(networks).find(
        ([networkName, config]): string => {
          if (config.network_id == returnNetwork.network_id) return networkName;
          return "";
        }
      );
      returnNetwork.name = result![0];
    }
  }
  // let returnNetworkLocalhost: Network = {
  //   name: "hardhat",
  //   network_id: 31337,
  //   accounts: [PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3],
  // };
  if (returnNetwork === undefined) {
    throw new Error("Network not found");
  }
  return returnNetwork;
}

export interface ProviderOrWallet {
  provider: ethers.providers.JsonRpcProvider;
  wallet: ethers.Wallet;
}

export async function getProviderOrWallet(
  networkId: number | string
): Promise<ProviderOrWallet> {
  const networkConfig = getNetworkObjFromId(networkId);
  const provider = new ethers.providers.JsonRpcProvider(networkConfig.url);
  const wallet = new ethers.Wallet(networkConfig.accounts[0]!, provider);
  return { provider, wallet };
}

export default {
  ...networks,
};
