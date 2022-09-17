require('dotenv').config();

import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ganache';
import '@nomiclabs/hardhat-etherscan';
import '@openzeppelin/hardhat-upgrades';

import 'hardhat-typechain';
import 'solidity-coverage';
import 'hardhat-deploy';
import 'hardhat-tracer';
import 'hardhat-log-remover';

import 'hardhat-gas-reporter';

import { task } from 'hardhat/config';
import { HardhatUserConfig } from 'hardhat/types';

const etherscanKey = process.env.ETHERSCAN_KEY;
const ALCHEMY_KEY = process.env.ALCHEMY_KEY;
const privateKeys = process.env.PRIVATE_KEYS ? process.env.PRIVATE_KEYS.split(',') : [];
const COINMARKETCAP_API = process.env.COINMARKETCAP_API;

function getHardhatPrivateKeys() {
    return privateKeys.map((key) => {
        const ONE_MILLION_ETH = '1000000000000000000000000';
        return {
            privateKey: key,
            balance: ONE_MILLION_ETH,
        };
    });
}

task('accounts', 'Prints the list of accounts', async (args, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(await account.address);
    }
});

const config: HardhatUserConfig = {
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            // hardfork: "istanbul",
            forking: {
                url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
                blockNumber: 13316039,
            },
            blockGasLimit: 12500000,
            accounts: getHardhatPrivateKeys(),
            tags: ['hardhat'],
        },
    },
    solidity: {
        version: '0.8.6',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    mocha: {
        timeout: 20000000,
    },
    etherscan: {
        apiKey: etherscanKey,
    },
    gasReporter: {
        gasPrice: 30,
        enabled: true,
        currency: 'USD',
        coinmarketcap: COINMARKETCAP_API,
        outputFile: 'gasReport.md',
        noColors: true,
    },
};

export default config;
