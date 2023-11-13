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
  const landId = MOPNMath.getTileLandId(coordinate);
  moveToRich(
    tokenContract,
    tokenId,
    coordinate,
    landId,
    await TheGraph.getMoveToTilesAccounts(coordinate)
  );
}

async function moveToRich(tokenContract, tokenId, coordinate, landId, tilesaccounts) {
  const accounthelper = await getContractObj("MOPNERC6551AccountHelper");
  const account = await accounthelper.checkAccountExist(
    await getContractAddress("MOPNERC6551AccountProxy"),
    hre.network.config.chainId,
    tokenContract,
    tokenId,
    0
  );
  const mopn = await getContractObj("MOPN");
  let tx;
  if (account.exist) {
    const accountContract = await getContractObj("MOPNERC6551Account", account._account);
    if (
      (await accountContract.isOwner((await getCurrentAccount()).address)) ||
      (await mopn.getAccountOnMapMOPNPoint(account._account)) == 0
    ) {
      tx = await mopn
        .connect(await getCurrentAccount())
        .moveTo(account._account, coordinate, landId, tilesaccounts);
    } else {
      console.log("account is placed");
      return;
    }
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

async function buyLandByMT() {
  const auctionhouse = await getContractObj("MOPNAuctionHouse");
  const price = await auctionhouse.getLandCurrentPrice();
  const tx = await auctionhouse.buyLand();
  console.log(
    "wallet",
    (await getCurrentAccount()).address,
    "buy land at price",
    price,
    "tx sent!"
  );
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

async function buyLandByETH(amount) {
  const mopnland = await getContractObj("MOPNLand");
  const price = await mopnland.ethMintTotalPrice(amount);
  const tx = await mopnland.ethMint(amount, { value: price });
  console.log(
    "wallet",
    (await getCurrentAccount()).address,
    "buy " + amount + " land with total price",
    price,
    "tx sent!"
  );
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

async function mintMockNFTs(contract, amount) {
  const mocknft = await getContractObj("MOCKNFT", contract);
  const tx = await mocknft.connect(await getCurrentAccount()).mint(amount);
  console.log(
    "wallet",
    (await getCurrentAccount()).address,
    "mint " + amount + " mock " + (await mocknft.name()) + " nfts",
    "tx sent!"
  );
  console.log(hre.network.config.etherscanHost + "tx/" + tx.hash);
  await tx.wait();
}

async function getMockNFTTokenUri(contract, tokenId) {
  const mocknft = await getContractObj("MOCKNFT", contract);
  return await mocknft.tokenURI(tokenId);
}

async function rentNFT_acceptOffer(
  tokenContract,
  tokenId,
  price,
  duration,
  offererIndex,
  ownerIndex
) {
  const MOPNERC6551AccountHelper = await getContractObj("MOPNERC6551AccountHelper");
  const MOPNLand = await getContractObj("MOPNLand");
  const MOPNRental = await getContractObj("MOPNRental");
  const WETH = await getContractObj("WETH");
  setCurrentAccount(offererIndex);
  const offerer = await getCurrentAccount();
  await WETH.connect(offerer).approve(await MOPNRental.getAddress(), price * duration);
  [accountexist, account] = await MOPNERC6551AccountHelper.checkAccountExist(
    await getContractAddress("MOPNERC6551AccountProxy"),
    hre.network.config.chainId,
    tokenContract,
    tokenId,
    0
  );
  const offerOrder = {
    orderType: 1, // 1 for OFFER
    orderId: Math.floor(Date.now() / 1000),
    owner: await offerer.getAddress(),
    nftToken: tokenContract,
    implementation: await getContractAddress("MOPNERC6551AccountProxy"),
    account: account,
    quantity: 1,
    price: price,
    minDuration: duration,
    maxDuration: duration,
    expiry: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
    feeRate: "25",
    feeReceiver: await MOPNLand.ADDR_TREASURY(),
    salt: "0",
  };
  const signature = await createSignature(await MOPNRental.getAddress(), offerOrder, offerer);
  setCurrentAccount(ownerIndex);
  const owner = await getCurrentAccount();

  let tx;
  if (accountexist) {
    const accountContract = await getContractObj("MOPNERC6551Account");
    if ((await accountContract.ownershipMode()) != 1) {
      tx = await accountContract.connect(owner).setOwnershipMode(1);
      await tx.wait();
    } else if ((await accountContract.rentEndBlock()) > (await ethers.provider.getBlockNumber())) {
      console.log("last rent not finish");
      return;
    }
  } else {
    tx = await MOPNERC6551AccountHelper.connect(owner).createAccount(
      await getContractAddress("MOPNERC6551AccountProxy"),
      hre.network.config.chainId,
      tokenContract,
      tokenId,
      0,
      accountContract.interface.encodeFunctionData("setOwnershipMode", [1])
    );
    await tx.wait();
  }

  await MOPNRental.connect(owner).acceptOffer(
    offerOrder,
    100,
    [account],
    price * duration,
    signature
  );
}

async function rentNFT_rentFromList(
  tokenContract,
  tokenId,
  price,
  duration,
  ownerIndex,
  renterIndex
) {
  const MOPNERC6551AccountHelper = await getContractObj("MOPNERC6551AccountHelper");
  const MOPNLand = await getContractObj("MOPNLand");
  const MOPNRental = await getContractObj("MOPNRental");
  setCurrentAccount(ownerIndex);
  const owner = await getCurrentAccount();
  [accountexist, account] = await MOPNERC6551AccountHelper.checkAccountExist(
    await getContractAddress("MOPNERC6551AccountProxy"),
    hre.network.config.chainId,
    tokenContract,
    tokenId,
    0
  );
  listOrder = {
    orderType: "0", // 0 for LIST
    orderId: Math.floor(Date.now() / 1000),
    owner: await owner.getAddress(),
    nftToken: tokenContract,
    implementation: await getContractAddress("MOPNERC6551AccountProxy"),
    account: account,
    quantity: "1",
    price: price,
    minDuration: duration,
    maxDuration: duration,
    expiry: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
    feeRate: "25",
    feeReceiver: await MOPNLand.ADDR_TREASURY(),
    salt: "0",
  };
  const signature = await createSignature(await MOPNRental.getAddress(), listOrder, owner);
  setCurrentAccount(renterIndex);
  const renter = await getCurrentAccount();

  let tx;
  if (accountexist) {
    const accountContract = await getContractObj("MOPNERC6551Account");
    if ((await accountContract.ownershipMode()) != 1) {
      tx = await accountContract.connect(owner).setOwnershipMode(1);
      await tx.wait();
    } else if ((await accountContract.rentEndBlock()) > (await ethers.provider.getBlockNumber())) {
      console.log("last rent not finish");
      return;
    }
  } else {
    tx = await MOPNERC6551AccountHelper.connect(owner).createAccount(
      await getContractAddress("MOPNERC6551AccountProxy"),
      hre.network.config.chainId,
      tokenContract,
      tokenId,
      0,
      accountContract.interface.encodeFunctionData("setOwnershipMode", [1])
    );
    await tx.wait();
  }

  await MOPNRental.connect(renter).rentFromList(listOrder, 100, signature, {
    value: price * duration,
  });
}

async function getAccountNFTOwner(account) {
  const accountContract = await getContractObj("MOPNERC6551Account", account);
  return await accountContract.nftowner();
}

async function getAccountNFTInfo(account) {
  const accountContract = await getContractObj("MOPNERC6551Account", account);
  return await accountContract.token();
}

async function getCurrentLandId() {
  return (await getContractObj("MOPNLand")).nextTokenId();
}

module.exports = {
  getContractAddress,
  getContractObj,
  moveTo,
  moveToRich,
  setCurrentAccount,
  buybomb,
  stackMT,
  removeStakingMT,
  buyLandByMT,
  buyLandByETH,
  mintMockNFTs,
  getMockNFTTokenUri,
  rentNFT_acceptOffer,
  rentNFT_rentFromList,
  getAccountNFTOwner,
  getAccountNFTInfo,
  getCurrentLandId,
};
