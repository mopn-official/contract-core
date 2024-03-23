
/* global ethers task */
require('@nomiclabs/hardhat-waffle')
require("@nomicfoundation/hardhat-verify");
require("hardhat-diamond-abi");
require("hardhat-gas-reporter");

const dotenv = require("dotenv");
dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.23",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000000,
          },
        },
      },
    ],
  },
  diamondAbi: {
    name: "MOPN",
    include: [
      "MOPNAuctionHouseFacet",
      "MOPNDataFacet",
      "MOPNFacet",
      "MOPNGovernanceFacet",
    ],
    strict: false,
  },
  networks: {
    "sepolia": {
      url: process.env.SEPOLIA_URL,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    "blast_sepolia": {
      url: process.env.BLAST_TEST_URI,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    "blast": {
      url: process.env.BLAST_TEST_URI,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    }
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY,
      blast_sepolia: process.env.BLASTSCAN_API_KEY, // apiKey is not required, just set a placeholder
    }
  },
  sourcify: {
    enabled: true
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_APIKEY,
  },
}
