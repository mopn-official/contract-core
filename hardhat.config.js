require("@nomicfoundation/hardhat-toolbox");
require("solidity-docgen");
const dotenv = require("dotenv");

dotenv.config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    localhost: {
      url: `http://localhost:7545`,
      accounts: ["39a3c68019306ff19c926041d34531d06e72ccc9fc63d32f3cdf1fd4e86587f3"],
    },
    goerli: {
      url: process.env.GOERLI_URL,
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
    },
  },
  docgen: {
    pages: "files",
  },
};
