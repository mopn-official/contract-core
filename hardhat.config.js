require("@nomicfoundation/hardhat-toolbox");
require("hardhat-change-network");
require("solidity-docgen");
const dotenv = require("dotenv");

dotenv.config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000,
          },
        },
      },
      {
        version: "0.4.18",
      },
      {
        version: "0.4.11",
      },
    ],
  },
  networks: {
    // hardhat: {
    //   mining: {
    //     auto: false,
    //     interval: 0
    //   }
    // },
    hardhat: {
      forking: {
        url: process.env.GOERLI_URL,
        blockNumber: 10081379,
      },
    },
    localhost: {
      url: `http://127.0.0.1:7545`,
      chainId: 1337,
      accounts: ["39a3c68019306ff19c926041d34531d06e72ccc9fc63d32f3cdf1fd4e86587f3"],
    },
    mainnet: {
      url: process.env.MAINNET_URL,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli: {
      url: process.env.GOERLI_URL,
      chainId: 5,
      etherscanHost: "https://goerli.etherscan.io/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli_dev: {
      url: process.env.GOERLI_URL,
      chainId: 5,
      etherscanHost: "https://goerli.etherscan.io/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    sepolia: {
      url: process.env.SEPOLIA_URL,
      etherscanHost: "https://sepolia.etherscan.io/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mumbai: {
      url: process.env.POLYGON_MUMBAI_URL,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    blast_test: {
      url: process.env.BLAST_TEST_URL,
      chainId: 168587773,
      etherscanHost: "https://testnet.blastscan.io/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_APIKEY,
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
      goerli: process.env.ETHERSCAN_API_KEY,
      rinkeby: process.env.ETHERSCAN_API_KEY,
      polygonMumbai: process.env.POLYSCAN_API_KEY,
    },
  },
  docgen: {
    pages: "files",
  },
};
