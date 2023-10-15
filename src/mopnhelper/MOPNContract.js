const { ethers } = require("hardhat");
const axios = require("axios");
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
      const response = await axios.get(
        "https://raw.githubusercontent.com/mopn-official/contract-core/stable-dev/configs/" +
          hre.network.name +
          ".json"
      );
      contractAddresses = response.data.contracts;
    } catch (error) {
      console.error(error);
    }
  }
  // console.log(contractName, contractAddresses[contractName]);
  return contractAddresses[contractName];
}

async function getContractObj(contractName, address) {
  if (address) {
    return await ethers.getContractAt(contractName, address);
  } else {
    if (!contractObjs.hasOwnProperty(contractName)) {
      contractObjs[contractName] = await ethers.getContractAt(
        contractName,
        await getContractAddress(contractName)
      );
    }
    return contractObjs[contractName];
  }
}

async function moveTo(tokenContract, tokenId, coordinate) {
  const accounthelper = await getContractObj("MOPNERC6551AccountHelper");
  const account = await accounthelper.checkAccountExist(
    await getContractAddress("MOPNERC6551AccountProxy"),
    hre.network.config.chainId,
    tokenContract,
    tokenId,
    0
  );
  const mopn = await getContractObj("MOPN");
  const landId = MOPNMath.getTileLandId(coordinate);
  let tx;
  if (account.exist) {
    const accountContract = await getContractObj("MOPNERC6551Account", account._account);
    if ((await accountContract.ownershipMode()) == 0) {
      if (await accountContract.isOwner((await getCurrentAccount()).address)) {
        tx = await mopn
          .connect(await getCurrentAccount())
          .moveToByOwner(
            account._account,
            coordinate,
            landId,
            await TheGraph.getMoveToTilesAccounts(coordinate)
          );
      } else if ((await mopn.getAccountOnMapMOPNPoint(account._account)) == 0) {
        tx = await accountContract
          .connect(await getCurrentAccount())
          .multicall([
            accountContract.interface.encodeFunctionData("lend"),
            accountContract.interface.encodeFunctionData("execute", [
              mopn.address,
              0,
              mopn.interface.encodeFunctionData("moveToByOwner", [
                account._account,
                coordinate,
                landId,
                await TheGraph.getMoveToTilesAccounts(coordinate),
              ]),
              0,
            ]),
          ]);
      } else {
        console.log("account is using by other user");
        return;
      }
    } else {
      tx = await mopn
        .connect(await getCurrentAccount())
        .moveToByOwner(
          account._account,
          coordinate,
          landId,
          await TheGraph.getMoveToTilesAccounts(coordinate)
        );
    }
  } else {
    const erc721Contract = await getContractObj("IERC721", tokenContract);
    if ((await erc721Contract.ownerOf(tokenId)) == (await getCurrentAccount()).address) {
      tx = await mopn
        .connect(await getCurrentAccount())
        .moveToNFT(
          tokenContract,
          tokenId,
          coordinate,
          landId,
          await TheGraph.getMoveToTilesAccounts(coordinate),
          (
            await ethers.getContractFactory("MOPNERC6551Account")
          ).interface.encodeFunctionData("setOwnershipMode", [1])
        );
    } else {
      tx = await mopn
        .connect(await getCurrentAccount())
        .moveToNFT(
          tokenContract,
          tokenId,
          coordinate,
          landId,
          await TheGraph.getMoveToTilesAccounts(coordinate),
          (
            await ethers.getContractFactory("MOPNERC6551Account")
          ).interface.encodeFunctionData("lend")
        );
    }
  }

  console.log(
    "wallet",
    (await getCurrentAccount()).address,
    "move",
    tokenContract,
    tokenId,
    "account",
    account._account,
    "to",
    coordinate,
    "tx sent!"
  );
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

async function moveToWithTilesAccounts(tokenContract, tokenId, coordinate, tilesaccounts) {
  const accounthelper = await getContractObj("MOPNERC6551AccountHelper");
  const account = await accounthelper.checkAccountExist(
    await getContractAddress("MOPNERC6551AccountProxy"),
    hre.network.config.chainId,
    tokenContract,
    tokenId,
    0
  );
  const mopn = await getContractObj("MOPN");
  const landId = MOPNMath.getTileLandId(coordinate);
  let tx;
  if (account.exist) {
    tx = await mopn
      .connect(await getCurrentAccount())
      .moveToByOwner(account._account, coordinate, landId, tilesaccounts);
  } else {
    tx = await mopn
      .connect(await getCurrentAccount())
      .moveToNFT(tokenContract, tokenId, coordinate, landId, tilesaccounts, "0x");
  }

  console.log(
    "wallet",
    (await getCurrentAccount()).address,
    "move",
    tokenContract,
    tokenId,
    "account",
    account._account,
    "to",
    coordinate,
    "tx sent!"
  );
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

async function buybomb(amount) {
  const auctionhouse = await getContractObj("MOPNAuctionHouse");
  const price = await auctionhouse.getBombCurrentPrice();
  const totalPrice = price * amount;
  const mopntoken = await getContractObj("MOPNToken");
  const tx = await mopntoken
    .connect(await getCurrentAccount())
    .safeTransferFrom(
      (
        await getCurrentAccount()
      ).address,
      auctionhouse.address,
      totalPrice,
      ethers.utils.defaultAbiCoder.encode(["uint256", "uint256"], [1, amount])
    );
  console.log(
    "wallet",
    (await getCurrentAccount()).address,
    "buy",
    amount,
    "bombs at price",
    price,
    "with total price",
    totalPrice,
    "tx sent!"
  );
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

async function stackMT(collectionAddress, amount) {
  const mopntoken = await getContractObj("MOPNToken");
  const governance = await getContractObj("MOPNGovernance");
  let vaultAddress = await governance.getCollectionVault(collectionAddress);
  let tx;
  if (vaultAddress != ethers.constants.AddressZero) {
    tx = await mopntoken
      .connect(await getCurrentAccount())
      .safeTransferFrom((await getCurrentAccount()).address, vaultAddress, amount, "0x");
    console.log(
      "wallet",
      (await getCurrentAccount()).address,
      "transfer",
      amount,
      "mopntoken to vault",
      vaultAddress,
      "for staking collection",
      collectionAddress,
      "tx sent!"
    );
  } else {
    vaultAddress = await governance.computeCollectionVault(collectionAddress);
    tx = await mopntoken
      .connect(await getCurrentAccount())
      .multicall([
        mopntoken.interface.encodeFunctionData("createCollectionVault", [collectionAddress]),
        mopntoken.interface.encodeFunctionData("safeTransferFrom", [
          (await getCurrentAccount()).address,
          vaultAddress,
          amount,
          "0x",
        ]),
      ]);
    console.log(
      "wallet",
      (await getCurrentAccount()).address,
      "create vault",
      vaultAddress,
      "and transfer",
      amount,
      "mopntoken to it for staking collection",
      collectionAddress,
      "tx sent!"
    );
  }
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  const receipt = await tx.wait();
  const mopn = await getContractObj("MOPN");
  const mopncollectionvault = await getContractObj("MOPNCollectionVault", vaultAddress);
  for (log of receipt.logs) {
    if (log.address == mopn.address) {
      const event = mopn.interface.parseLog(log);
      if (event.name == "CollectionPointChange") {
        console.log(
          "Collection Point Change To",
          ethers.utils.formatUnits(event.args.CollectionPoint, 2)
        );
      }
    } else if (log.address == mopncollectionvault.address) {
      const event = mopncollectionvault.interface.parseLog(log);
      if (event.name == "MTDeposit") {
        console.log("receive", ethers.utils.formatEther(event.args.VTAmount), "vtoken");
      }
    }
  }
}

async function removeStakingMT(collectionAddress, amount) {
  const governance = await getContractObj("MOPNGovernance");
  let vaultAddress = await governance.getCollectionVault(collectionAddress);
  if (vaultAddress == ethers.constants.AddressZero) {
    console.log("collection vault not create yet");
    return;
  }

  const collectionVault = await getContractObj("MOPNCollectionVault", vaultAddress);
  const tx = await collectionVault.withdraw(amount);
  console.log(
    "wallet",
    (await getCurrentAccount()).address,
    "remove collection",
    collectionAddress,
    "staking with",
    amount,
    "vtoken from vault address",
    vaultAddress,
    "tx sent!"
  );
  const receipt = await tx.wait();
  const mopn = await getContractObj("MOPN");
  for (log of receipt.logs) {
    if (log.address == collectionVault.address) {
      const event = collectionVault.interface.parseLog(log);
      if (event.name == "MTWithdraw") {
        console.log("receive", ethers.utils.formatUnits(event.args.MTAmount, 6), "mopn token");
      }
    } else if (log.address == mopn.address) {
      const event = mopn.interface.parseLog(log);
      if (event.name == "CollectionPointChange") {
        console.log(
          "Collection Point Change To",
          ethers.utils.formatUnits(event.args.CollectionPoint, 2)
        );
      }
    }
  }
}

module.exports = {
  getContractAddress,
  getContractObj,
  moveTo,
  moveToWithTilesAccounts,
  setCurrentAccount,
  buybomb,
  stackMT,
  removeStakingMT,
};
