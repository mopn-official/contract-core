const { ethers } = require("hardhat");
const axios = require('axios');
const MOPNMath = require("../simulator/MOPNMath");
const TheGraph = require("./TheGraph");

let contractAddresses = null;

let contractObjs = {};

let currentAccount = 0;

function setCurrentAccount(accountIndex) {
  currentAccount = accountIndex;
}

async function getCurrentAccount() {
  let accounts = await ethers.getSigners();
  return accounts[currentAccount];
}

async function getContractAddress(contractName) {
  if (contractAddresses == null) {
    try {
      const response = await axios.get('https://raw.githubusercontent.com/mopn-official/contract-core/stable-dev/configs/' + hre.network.name + '.json');
      contractAddresses = response.data.contracts;
    } catch (error) {
      console.error(error);
    }
  }
  console.log(contractName, contractAddresses[contractName]);
  return contractAddresses[contractName];
}

async function getContractObj(contractName) {
  if (!contractObjs.hasOwnProperty(contractName)) {
    contractObjs[contractName] = await ethers.getContractAt(contractName, await getContractAddress(contractName));
  }
  return contractObjs[contractName];
}

async function moveTo(tokenContract, tokenId, coordinate) {
  const accounthelper = await getContractObj('MOPNERC6551AccountHelper');
  const account = await accounthelper.checkAccountExist(
    await getContractAddress('MOPNERC6551AccountProxy'),
    hre.network.config.chainId,
    tokenContract,
    tokenId,
    0
  );
  const mopn = await getContractObj('MOPN');
  const landId = MOPNMath.getTileLandId(coordinate);
  let tx;
  if (account.exist) {
    tx = await mopn.connect(await getCurrentAccount()).moveToByOwner(account._account, coordinate, landId, await TheGraph.getMoveToTilesAccounts(coordinate));
  } else {
    tx = await mopn.connect(await getCurrentAccount()).moveToNFT(tokenContract, tokenId, coordinate, landId, await TheGraph.getMoveToTilesAccounts(coordinate), "0x");
  }

  console.log("wallet", (await getCurrentAccount()).address, "move", tokenContract, tokenId, "account", account._account, "to", coordinate, "tx sent!");
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

async function bidNFT(tokenContract, tokenId) {
  const accounthelper = await getContractObj('MOPNERC6551AccountHelper');
  const account = await accounthelper.checkAccountExist(
    await getContractAddress('MOPNERC6551AccountProxy'),
    hre.network.config.chainId,
    tokenContract,
    tokenId,
    0
  );
  const ownershipbidding = await getContractObj("MOPNERC6551AccountOwnershipBidding");
  const minimalPrice = await ownershipbidding.getMimimalBidPrice(account._account, tokenContract);
  let tx;
  if (account.exist) {
    tx = await ownershipbidding.connect(await getCurrentAccount()).bidAccountTo(account._account, (await getCurrentAccount()).address, { value: minimalPrice });
  } else {
    tx = await ownershipbidding.connect(await getCurrentAccount()).bidNFTTo(tokenContract, tokenId, (await getCurrentAccount()).address, { value: minimalPrice });
  }

  console.log("wallet", (await getCurrentAccount()).address, "bid", tokenContract, tokenId, "account", account._account, "with minimal price", minimalPrice, "tx sent!");
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

async function buybomb(amount) {
  const auctionhouse = await getContractObj('MOPNAuctionHouse');
  const price = await auctionhouse.getBombCurrentPrice();
  const totalPrice = price * amount;
  const mopntoken = await getContractObj('MOPNToken');
  const tx = await mopntoken.connect(await getCurrentAccount()).safeTransferFrom((await getCurrentAccount()).address, auctionhouse.address, totalPrice, ethers.utils.defaultAbiCoder.encode(["uint256", "uint256"], [1, amount]))
  console.log("wallet", (await getCurrentAccount()).address, "buy", amount, "bombs at price", price, "with total price", totalPrice, "tx sent!");
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

module.exports = {
  getContractAddress,
  getContractObj,
  moveTo,
  bidNFT,
  setCurrentAccount,
  buybomb
};
