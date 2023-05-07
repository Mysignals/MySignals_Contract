require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("solidity-coverage");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const MAINNET_RPC_URL =
    process.env.MAINNET_RPC_URL ||
    process.env.ALCHEMY_MAINNET_RPC_URL ||
    "https://eth-mainnet.alchemyapi.io/v2/your-api-key";
const GOERLI_RPC_URL =
    process.env.GOERLI_RPC_URL || "https://eth-goerli.alchemyapi.io/v2/your-api-key";
const POLYGON_MAINNET_RPC_URL =
    process.env.POLYGON_MAINNET_RPC_URL ||
    "https://polygon-mainnet.alchemyapi.io/v2/your-api-key";

const BSCCHAINURL = process.env.BSCCHAINURL || "";
const BSCTESTCHAINURL = process.env.BSCTESTCHAINURL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x";
// optional
const MNEMONIC = process.env.MNEMONIC || "your mnemonic";

// Your API key for Etherscan, obtain one at https://etherscan.io/
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API || "Your etherscan API key";
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "Your polygonscan API key";
const BSCSCAN_API = process.env.BSCSCAN_API || "Your BSCScan Api Key";
const REPORT_GAS = process.env.REPORT_GAS || false;

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            // // If you want to do some forking, uncomment this
            // forking: {
            //   url: MAINNET_RPC_URL
            // }
            chainId: 31337,
            blockConfirmations: 1,
        },
        localhost: {
            blockConfirmations: 1,
            chainId: 31337,
        },
        goerli: {
            url: GOERLI_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            //   accounts: {
            //     mnemonic: MNEMONIC,
            //   },
            saveDeployments: true,
            blockConfirmations: 3,
            chainId: 5,
        },
        mainnet: {
            url: MAINNET_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            //   accounts: {
            //     mnemonic: MNEMONIC,
            //   },
            blockConfirmations: 1,
            saveDeployments: true,
            chainId: 1,
        },
        bsc: {
            url: BSCCHAINURL,
            accounts: [PRIVATE_KEY],
            chainId: 56,
            blockConfirmations: 3,
            saveDeployments: true,
        },
        bsctest: {
            url: BSCTESTCHAINURL,
            accounts: [PRIVATE_KEY],
            chainId: 97,
            blockConfirmations: 3,
            saveDeployments: true,
        },
        polygon: {
            url: POLYGON_MAINNET_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            blockConfirmations: 1,
            chainId: 137,
        },
    },
    etherscan: {
        // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
        apiKey: {
            goerli: ETHERSCAN_API_KEY,
            polygon: POLYGONSCAN_API_KEY,
            bsc: BSCSCAN_API,
            bscTestnet: BSCSCAN_API,
        },
    },
    gasReporter: {
        enabled: REPORT_GAS,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    },
    contractSizer: {
        runOnCompile: true,
        only: ["MySignalApp"],
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
        player: {
            default: 1,
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.7",
            },
            {
                version: "0.4.24",
            },
            {
                version: "0.6.6",
            },
            {
                version: "0.8.18",
            },
        ],
    },
    mocha: {
        timeout: 500000, // 500 seconds max for running tests
    },
};
