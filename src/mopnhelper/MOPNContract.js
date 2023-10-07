const { ethers } = require("hardhat");
const axios = require('axios');

let contractAddresses = null;

async function getContractAddress(contractName) {
  if (contractAddresses == null) {
    try {
      const response = await axios.get('https://raw.githubusercontent.com/mopn-official/contract-core/stable-dev/configs/' + hre.network.name + '.json');
      contractAddresses = response.data.contracts;
    } catch (error) {
      console.error(error);
    }
  }

  return contractAddresses[contractName];
}

module.exports = {
  getContractAddress
};
