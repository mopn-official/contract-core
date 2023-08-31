const { ethers } = require("hardhat");
const fs = require("fs");
const { time, mine } = require("@nomicfoundation/hardhat-network-helpers");

describe("MOPN", function () {
  let testnft,
    testnft1,
    owner,
    owner1,
    erc6551registry,
    erc6551account,
    erc6551accountproxy,
    erc6551accounthelper,
    tileMath,
    mopngovernance,
    mopnauctionHouse,
    mopn,
    mopnbomb,
    mopnpoint,
    mopnmt,
    mopnData,
    mopncollectionVault,
    mtdecimals,
    mopnland,
    mopnlandMetaDataRender,
    accounts = [],
    collections = [];

  it("deply Governance", async function () {
    const MOPNGovernance = await ethers.getContractFactory("MOPNGovernance");
    mopngovernance = await MOPNGovernance.deploy();
    await mopngovernance.deployed();
    console.log("MOPNGovernance", mopngovernance.address);
  });

  it("deply erc6551", async function () {
    const ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
    erc6551registry = await ERC6551Registry.deploy();
    await erc6551registry.deployed();
    console.log("ERC6551Registry", erc6551registry.address);

    const MOPNERC6551Account = await ethers.getContractFactory("MOPNERC6551Account");
    erc6551account = await MOPNERC6551Account.deploy(mopngovernance.address);
    await erc6551account.deployed();
    console.log("MOPNERC6551Account", erc6551account.address);

    const MOPNERC6551AccountProxy = await ethers.getContractFactory("MOPNERC6551AccountProxy");
    erc6551accountproxy = await MOPNERC6551AccountProxy.deploy(
      mopngovernance.address,
      erc6551account.address
    );
    await erc6551accountproxy.deployed();
    console.log("MOPNERC6551AccountProxy", erc6551accountproxy.address);

    const MOPNERC6551AccountHelper = await ethers.getContractFactory("MOPNERC6551AccountHelper");
    erc6551accounthelper = await MOPNERC6551AccountHelper.deploy(mopngovernance.address);
    await erc6551accounthelper.deployed();
    console.log("MOPNERC6551AccountHelper", erc6551accounthelper.address);
  });

  it("deploy TileMath", async function () {
    [owner, owner1] = await ethers.getSigners();
    console.log("owner", owner.address);

    const TileMath = await ethers.getContractFactory("TileMath");
    tileMath = await TileMath.deploy();
    await tileMath.deployed();
    console.log("TileMath", tileMath.address);
  });

  it("deploy TESTNFT", async function () {
    const TESTNFT = await ethers.getContractFactory("TESTNFT");
    testnft = await TESTNFT.deploy();
    await testnft.deployed();
    console.log("TESTNFT ", testnft.address);
    collections.push(testnft.address);

    const TESTNFT1 = await ethers.getContractFactory("TESTNFT");
    testnft1 = await TESTNFT1.deploy();
    await testnft1.deployed();
    console.log("TESTNFT1 ", testnft1.address);
    collections.push(testnft1.address);
  });

  it("deploy MOPN contracts", async function () {
    const unixTimeStamp = Math.floor(Date.now() / 1000) - 86000;
    console.log("start timestamp", unixTimeStamp);

    const AuctionHouse = await ethers.getContractFactory("MOPNAuctionHouse");
    mopnauctionHouse = await AuctionHouse.deploy(
      mopngovernance.address,
      unixTimeStamp,
      unixTimeStamp
    );
    await mopnauctionHouse.deployed();
    console.log("MOPNAuctionHouse", mopnauctionHouse.address);

    const MOPN = await ethers.getContractFactory("MOPN", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    mopn = await MOPN.deploy(mopngovernance.address, 60000000, 0, 50400, 10000, 99999);
    await mopn.deployed();
    console.log("MOPN", mopn.address);

    const MOPNData = await ethers.getContractFactory("MOPNData", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    mopnData = await MOPNData.deploy(mopngovernance.address);
    await mopnData.deployed();
    console.log("MOPNData", mopnData.address);

    const MOPNCollectionVault = await ethers.getContractFactory("MOPNCollectionVault");
    mopncollectionVault = await MOPNCollectionVault.deploy(mopngovernance.address);
    await mopncollectionVault.deployed();
    console.log("MOPNCollectionVault", mopncollectionVault.address);
  });

  it("deploy MOPNLand", async function () {
    const NFTSVG = await ethers.getContractFactory("NFTSVG");
    const nftsvg = await NFTSVG.deploy();
    await nftsvg.deployed();
    console.log("NFTSVG", nftsvg.address);

    const NFTMetaData = await ethers.getContractFactory("NFTMetaData", {
      libraries: {
        NFTSVG: nftsvg.address,
        TileMath: tileMath.address,
      },
    });
    const nftmetadata = await NFTMetaData.deploy();
    await nftmetadata.deployed();
    console.log("NFTMetaData", nftmetadata.address);

    const MOPNLandMetaDataRender = await ethers.getContractFactory("MOPNLandMetaDataRender", {
      libraries: {
        NFTMetaData: nftmetadata.address,
        TileMath: tileMath.address,
      },
    });
    mopnlandMetaDataRender = await MOPNLandMetaDataRender.deploy(mopngovernance.address);
    await mopnlandMetaDataRender.deployed();
    console.log("MOPNLandMetaDataRender", mopnlandMetaDataRender.address);

    const unixTimeStamp = Math.floor(Date.now() / 1000) - 86000;
    const MOPNLand = await ethers.getContractFactory("MOPNLand");
    mopnland = await MOPNLand.deploy(
      unixTimeStamp,
      200000000000000,
      1001,
      owner.address,
      mopnlandMetaDataRender.address,
      mopnauctionHouse.address
    );
    await mopnland.deployed();
    console.log("MOPNLand ", mopnland.address);

    console.log("mint some land");
    let minpasstx = await mopnland.ethMint(5, { value: "1000000000000000000" });
    await minpasstx.wait();
  });

  it("deploy Tokens", async function () {
    const MOPNBomb = await ethers.getContractFactory("MOPNBomb");
    mopnbomb = await MOPNBomb.deploy(mopngovernance.address);
    await mopnbomb.deployed();
    console.log("MOPNBomb", mopnbomb.address);

    const MOPNPoint = await ethers.getContractFactory("MOPNPoint");
    mopnpoint = await MOPNPoint.deploy(mopngovernance.address);
    await mopnpoint.deployed();
    console.log("MOPNPoint", mopnpoint.address);

    const MOPNToken = await ethers.getContractFactory("MOPNToken");
    mopnmt = await MOPNToken.deploy(mopngovernance.address);
    await mopnmt.deployed();
    console.log("MOPNToken", mopnmt.address);

    mtdecimals = await mopnmt.decimals();
    console.log("mtdecimals", mtdecimals);
  });

  it("update contract attributes", async function () {
    const governancesetmopntx = await mopngovernance.updateMOPNContracts(
      mopnauctionHouse.address,
      mopn.address,
      mopnbomb.address,
      mopnmt.address,
      mopnpoint.address,
      mopnland.address,
      mopnData.address,
      mopncollectionVault.address
    );
    await governancesetmopntx.wait();

    const governanceset6551tx = await mopngovernance.updateERC6551Contract(
      erc6551registry.address,
      erc6551accountproxy.address,
      erc6551accounthelper.address
    );
    await governanceset6551tx.wait();

    const governancesetaccounttx = await mopngovernance.add6551AccountImplementation(
      erc6551account.address
    );
    await governancesetaccounttx.wait();

    const setAuctionToLandtx = await mopnland.setAuction(mopnauctionHouse.address);
    await setAuctionToLandtx.wait();
  });

  it("transfer contract owners", async function () {
    const mttransownertx = await mopnmt.transferOwnership(mopngovernance.address);
    await mttransownertx.wait();

    const transownertx = await mopnbomb.transferOwnership(mopngovernance.address);
    await transownertx.wait();

    const landtransownertx = await mopnland.transferOwnership(mopngovernance.address);
    await landtransownertx.wait();
  });

  it("mint test nfts", async function () {
    let mintnfttx = await testnft.safeMint(owner.address, 8);
    await mintnfttx.wait();
    mintnfttx = await testnft1.safeMint(owner.address, 2);
    await mintnfttx.wait();
  });

  it("test moveTo step by step from account", async function () {
    mine(1);
    const tx = await erc6551registry.createAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      0,
      0,
      "0x"
    );
    await tx.wait();

    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      0,
      0
    );

    const accountProxyContract = await ethers.getContractAt("MOPNERC6551AccountProxy", account);
    console.log("account 1 implementation", await accountProxyContract.implementation());

    const accountContract = await ethers.getContractAt("MOPNERC6551Account", account);

    const tx1 = await accountContract.executeCall(
      mopn.address,
      0,
      // 0 1
      mopn.interface.encodeFunctionData("moveTo", [10001001, 0])
    );
    await tx1.wait();

    accounts.push(account);
  });

  it("test moveTo multicall from account proxy", async function () {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      1,
      0
    );

    const tx = await erc6551accounthelper.multicall([
      erc6551accounthelper.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        testnft.address,
        1,
        0,
        "0x",
      ]),
      erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
        account,
        mopn.address,
        0,
        // 0 3
        mopn.interface.encodeFunctionData("moveTo", [10001003, 0]),
      ]),
    ]);
    await tx.wait();

    accounts.push(account);
    console.log("account", account);
  });

  it("test multi moveTo multicall from account proxy", async function () {
    const account2 = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      2,
      0
    );
    accounts.push(account2);
    const account3 = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      3,
      0
    );
    accounts.push(account3);
    const account4 = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      4,
      0
    );
    accounts.push(account4);
    const account5 = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      5,
      0
    );
    accounts.push(account5);
    const account6 = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      6,
      0
    );
    accounts.push(account6);
    const account7 = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      7,
      0
    );
    accounts.push(account7);
    const account11 = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      testnft1.address,
      0,
      0
    );
    accounts.push(account11);

    const tx = await erc6551accounthelper.multicall([
      erc6551accounthelper.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        testnft.address,
        2,
        0,
        "0x",
      ]),
      erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
        account2,
        mopn.address,
        0,
        // 0 2
        mopn.interface.encodeFunctionData("moveTo", [10001002, 0]),
      ]),
      erc6551accounthelper.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        testnft.address,
        3,
        0,
        "0x",
      ]),
      erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
        account3,
        mopn.address,
        0,
        // 1 2
        mopn.interface.encodeFunctionData("moveTo", [10011002, 0]),
      ]),
      erc6551accounthelper.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        testnft.address,
        4,
        0,
        "0x",
      ]),
      erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
        account4,
        mopn.address,
        0,
        // -1 3
        mopn.interface.encodeFunctionData("moveTo", [9991003, 0]),
      ]),
      erc6551accounthelper.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        testnft.address,
        5,
        0,
        "0x",
      ]),
      erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
        account5,
        mopn.address,
        0,
        // -1 4
        mopn.interface.encodeFunctionData("moveTo", [9991004, 0]),
      ]),
      erc6551accounthelper.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        testnft.address,
        6,
        0,
        "0x",
      ]),
      erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
        account6,
        mopn.address,
        0,
        // 0 4
        mopn.interface.encodeFunctionData("moveTo", [10001004, 0]),
      ]),
      erc6551accounthelper.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        testnft.address,
        7,
        0,
        "0x",
      ]),
      erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
        account7,
        mopn.address,
        0,
        // 1 3
        mopn.interface.encodeFunctionData("moveTo", [10011003, 0]),
      ]),
      erc6551accounthelper.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        testnft1.address,
        0,
        0,
        "0x",
      ]),
      erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
        account11,
        mopn.address,
        0,
        // 4 0
        mopn.interface.encodeFunctionData("moveTo", [10041000, 0]),
      ]),
    ]);
    await tx.wait();

    await timeIncrease(500);

    await avatarInfo();
    await collectionInfo();
  });

  it("test transfer account MT", async function () {
    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );

    const params = [];
    for (let i = 0; i < accounts.length; i++) {
      const account = accounts[i];
      const amount = await mopnmt.balanceOf(account);
      params.push(
        erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
          account,
          mopnmt.address,
          0,
          mopnmt.interface.encodeFunctionData("transfer", [owner.address, amount]),
        ])
      );
    }

    const multitx1 = await erc6551accounthelper.multicall(params);
    await multitx1.wait();

    await avatarInfo();

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );

    const mintmttx = await mopngovernance.mintMT1(owner.address, 10000000000000);
    await mintmttx.wait();

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test auctionHouse", async function () {
    const allowanceTx = await mopnmt.approve(
      mopnauctionHouse.address,
      ethers.BigNumber.from("10000000000000000")
    );
    await allowanceTx.wait();

    console.log("Current Bomb round", await mopnauctionHouse.getBombRoundId());
    console.log("Current Bomb round sold", await mopnauctionHouse.getBombRoundSold());
    console.log(
      "current bomb price",
      ethers.utils.formatUnits(await mopnauctionHouse.getBombCurrentPrice(), mtdecimals)
    );

    const buybombtx = await mopnauctionHouse.buyBomb(5);
    await buybombtx.wait();

    const buybombtx1 = await mopnmt.safeTransferFrom(
      owner.address,
      mopnauctionHouse.address,
      (await mopnauctionHouse.getBombCurrentPrice()) * 6,
      ethers.utils.solidityPack(["uint256", "uint256"], [1, 5])
    );
    await buybombtx1.wait();

    console.log("Current Bomb round", await mopnauctionHouse.getBombRoundId());
    console.log("Current Bomb round sold", await mopnauctionHouse.getBombRoundSold());
    console.log(
      "current bomb price",
      ethers.utils.formatUnits(await mopnauctionHouse.getBombCurrentPrice(), mtdecimals)
    );

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test auction land", async function () {
    console.log("Current Land round", await mopnauctionHouse.getLandRoundId());
    console.log("Current Land price", await mopnauctionHouse.getLandCurrentPrice());

    const buylandtx = await mopnauctionHouse.buyLand();
    await buylandtx.wait();

    console.log("Current Land round", await mopnauctionHouse.getLandRoundId());
    console.log("Current Land price", await mopnauctionHouse.getLandCurrentPrice());

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test bomb", async function () {
    await avatarInfo();
    await collectionInfo();

    const account = accounts[8];
    const tx1 = await mopnbomb.safeTransferFrom(
      owner.address,
      account,
      1,
      1,
      ethers.utils.solidityPack(["uint256"], [10001002])
    );
    await tx1.wait();

    await avatarInfo();
    await collectionInfo();

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test mopndata batchClaimAccountMT", async function () {
    const tx = await mopn.batchClaimAccountMT([accounts.slice(0, 7), [accounts[8]]]);
    await tx.wait();

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test stakingMT", async function () {
    console.log(await mopnData.getCollectionData(collections[1]));

    const collection1 = collections[0];
    const collection2 = collections[1];

    console.log("create collection", collection1, "vault");
    const tx1 = await mopngovernance.createCollectionVault(collection1);
    await tx1.wait();

    const vault1 = await ethers.getContractAt(
      "MOPNCollectionVault",
      await mopngovernance.getCollectionVault(collection1)
    );
    console.log(collection1, "vault1", vault1.address);
    console.log(collection1, "collectionpoint 1", await mopn.getCollectionMOPNPoint(collection1));

    const tx2 = await mopnmt.safeTransferFrom(
      owner.address,
      vault1.address,
      ethers.BigNumber.from("1500000000"),
      "0x"
    );
    await tx2.wait();

    console.log("vault1 mt balance", await mopnmt.balanceOf(vault1.address));
    console.log(collection1, "collectionpoint 1", await mopn.getCollectionMOPNPoint(collection1));

    console.log("create collection", collection2, "multi call");
    const tx3 = await mopnmt.multicall([
      mopnmt.interface.encodeFunctionData("createCollectionVault", [collection2]),
      mopnmt.interface.encodeFunctionData("safeTransferFrom", [
        owner.address,
        await mopngovernance.computeCollectionVault(collection2),
        ethers.BigNumber.from("1500000000"),
        "0x",
      ]),
    ]);
    await tx3.wait();

    const vault2 = await ethers.getContractAt(
      "MOPNCollectionVault",
      await mopngovernance.getCollectionVault(collection2)
    );
    console.log(collection2, "vault2", vault2.address);
    console.log("vault2 mt balance", await mopnmt.balanceOf(vault2.address));
    console.log(collection2, "collectionpoint 2", await mopn.getCollectionMOPNPoint(collection2));

    console.log("vault1 nft offer price", await vault1.getNFTOfferPrice());
    const tx4 = await testnft.approve(vault1.address, 1);
    tx4.wait();
    console.log("accept vault1 nft offer");
    const tx5 = await vault1.acceptNFTOffer(1);
    tx5.wait();

    const vault2pmtbalance = await vault2.balanceOf(owner.address);
    console.log("vault2 pmt balance", vault2pmtbalance);
    console.log("vault2 mt balance", await mopnmt.balanceOf(vault2.address));
    const tx6 = await vault2.withdraw(vault2pmtbalance);
    tx6.wait();

    await collectionInfo();

    console.log(await mopnData.calcCollectionSettledMT(collection1));
    console.log(await mopnData.calcCollectionSettledMT(collection2));
  });

  it("test helpers", async function () {
    console.log(await mopnData.getAccountData(accounts[0]));
    console.log(await mopnData.getCollectionData(collections[0]));
    console.log(await mopnData.getCollectionData(collections[1]));
  });

  it("test additional point", async function () {
    const data = fs.readFileSync(__dirname + "/../scripts/additionalpoints/goerli_dev.json", "UTF-8");
    const bufferpoints = JSON.parse(data);
    const addresses = [];
    const points = [];
    for (let i = 0; i < bufferpoints.length; i++) {
      addresses.push(bufferpoints[i].address);
      points.push(parseInt(bufferpoints[i].top_offer_price.toFixed(2) * 100));
    }
    const tx1 = await mopn.batchSetCollectionAdditionalMOPNPoints(addresses, points);
    tx1.wait();

    await collectionInfo();
  });

  it("test land account", async function () {

    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      mopnland.address,
      0,
      0
    );
    console.log(account);
    console.log(await mopnData.calcAccountMT(account));
    console.log("land account", account, "balance", await mopnmt.balanceOf(account));

    console.log("land unclaimed mt", await mopnData.calcLandsMT([0]));
  });

  const avatarInfo = async () => {
    console.log("total Point", (await mopn.TotalMOPNPoints()).toString());
    for (const account of accounts) {
      console.log(
        "account",
        account,
        "collection",
        (await mopn.getAccountCollection(account)).toString(),
        "coordinate",
        await mopn.getAccountCoordinate(account),
        "getAccountBombUsed",
        (await mopnbomb.balanceOf(account, 1)).toString(),
        "getAccountPoint",
        (await mopn.getAccountOnMapMOPNPoint(account)).toString(),
        "getAccountMT",
        ethers.utils.formatUnits(await mopnmt.balanceOf(account), mtdecimals)
      );
    }
  };

  const collectionInfo = async () => {
    for (const collection of collections) {
      console.log(
        "collectionAddress",
        collection,
        "on map account number",
        (await mopn.getCollectionOnMapNum(collection)).toString(),
        "collection account points",
        (await mopn.getCollectionOnMapMOPNPoints(collection)).toString(),
        "collection points",
        (await mopn.getCollectionMOPNPoints(collection)).toString(),
        "collection additional points",
        (await mopn.getCollectionAdditionalMOPNPoints(collection)).toString()
      );
    }
  };

  const timeIncrease = async (seconds) => {
    console.log("increase", seconds, "seconds");
    await time.increase(seconds);
  };
});
