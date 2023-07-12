const { ethers } = require("hardhat");

describe("MOPN", function () {
  let testnft,
    testnft1,
    owner,
    owner1,
    erc6551registry,
    mopnerc6551account,
    mopnerc6551accountproxy,
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
    mopnbatchhelper,
    mopndatahelper,
    accounts = [],
    collections = [];

  it("deply Governance", async function () {
    const MOPNGovernance = await ethers.getContractFactory("MOPNGovernance");
    mopngovernance = await MOPNGovernance.deploy(31337);
    await mopngovernance.deployed();
    console.log("MOPNGovernance", mopngovernance.address);
  });

  it("deply erc6551", async function () {
    const ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
    erc6551registry = await ERC6551Registry.deploy();
    await erc6551registry.deployed();
    console.log("ERC6551Registry", erc6551registry.address);

    const MOPNERC6551AccountProxy = await ethers.getContractFactory("MOPNERC6551AccountProxy");
    mopnerc6551accountproxy = await MOPNERC6551AccountProxy.deploy(mopngovernance.address);
    await mopnerc6551accountproxy.deployed();
    console.log("MOPNERC6551AccountProxy", mopnerc6551accountproxy.address);

    const MOPNERC6551Account = await ethers.getContractFactory("MOPNERC6551Account");
    mopnerc6551account = await MOPNERC6551Account.deploy(mopnerc6551accountproxy.address);
    await mopnerc6551account.deployed();
    console.log("MOPNERC6551Account", mopnerc6551account.address);
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
    const unixTimeStamp = Math.floor(Date.now() / 1000) - 73200;
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
    mopn = await MOPN.deploy(mopngovernance.address);
    await mopn.deployed();
    console.log("MOPN", mopn.address);

    const MOPNData = await ethers.getContractFactory("MOPNData");
    mopnData = await MOPNData.deploy(mopngovernance.address, unixTimeStamp);
    await mopnData.deployed();
    console.log("MOPNData", mopnData.address);

    const MOPNCollectionVault = await ethers.getContractFactory("MOPNCollectionVault");
    mopncollectionVault = await MOPNCollectionVault.deploy(mopngovernance.address);
    await mopncollectionVault.deployed();
    console.log("MOPNCollectionVault", mopncollectionVault.address);
  });

  it("deploy MOPNLand", async function () {
    const MOPNLand = await ethers.getContractFactory("MOPNLandMirror");
    mopnland = await MOPNLand.deploy();
    await mopnland.deployed();
    console.log("MOPNLand ", mopnland.address);

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

    console.log("mint some land");
    let minpasstx = await mopnland.claim(owner.address, 0);
    await minpasstx.wait();
    minpasstx = await mopnland.claim(owner.address, 100);
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

  it("deploy helpers", async function () {
    const MOPNBatchHelper = await ethers.getContractFactory("MOPNBatchHelper");
    mopnbatchhelper = await MOPNBatchHelper.deploy(mopngovernance.address);
    await mopnbatchhelper.deployed();
    console.log("MOPNBatchHelper", mopnbatchhelper.address);

    const MOPNDataHelper = await ethers.getContractFactory("MOPNDataHelper");
    mopndatahelper = await MOPNDataHelper.deploy(mopngovernance.address);
    await mopndatahelper.deployed();
    console.log("MOPNDataHelper", mopndatahelper.address);
  });

  it("transfer contract owners", async function () {
    const mttransownertx = await mopnmt.transferOwnership(mopngovernance.address);
    await mttransownertx.wait();

    const transownertx = await mopnbomb.transferOwnership(mopngovernance.address);
    await transownertx.wait();

    const landtransownertx = await mopnland.transferOwnership(mopngovernance.address);
    await landtransownertx.wait();
  });

  it("update contract attributes", async function () {
    const governancesetroottx = await mopngovernance.updateWhiteList(
      "0x8a746c884b5d358e2337e88b5da1afe745ffe4a3a5a378819ec41d0979c9931b"
    );
    await governancesetroottx.wait();

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
      mopnerc6551account.address
    );
    await governanceset6551tx.wait();
  });

  it("mint test nfts", async function () {
    let mintnfttx = await testnft.safeMint(owner.address, 8);
    await mintnfttx.wait();
    mintnfttx = await testnft1.safeMint(owner.address, 2);
    await mintnfttx.wait();
  });

  it("test moveTo from account", async function () {
    const tx = await erc6551registry.createAccount(
      mopnerc6551account.address,
      31337,
      testnft.address,
      0,
      0,
      "0x"
    );
    await tx.wait();

    const account = await erc6551registry.account(
      mopnerc6551account.address,
      31337,
      testnft.address,
      0,
      0
    );
    accounts.push(account);
    console.log("account", account);

    const accountContract = await ethers.getContractAt("MOPNERC6551Account", account);

    const tx1 = await accountContract.executeCall(
      mopn.address,
      0,
      // 0 1
      mopn.interface.encodeFunctionData("moveTo", [10001001, 0])
    );
    await tx1.wait();
  });

  it("test moveTo from account proxy", async function () {
    const account = await mopnerc6551accountproxy.computeAccount(
      mopnerc6551account.address,
      31337,
      testnft.address,
      1,
      0
    );
    accounts.push(account);
    console.log("account", account);

    const tx = await mopnerc6551accountproxy.multicall([
      mopnerc6551accountproxy.interface.encodeFunctionData("createAccount", [
        mopnerc6551account.address,
        31337,
        testnft.address,
        1,
        0,
        "0x",
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("proxyCall", [
        account,
        mopn.address,
        0,
        // 0 3
        mopn.interface.encodeFunctionData("moveTo", [10001003, 0]),
      ]),
    ]);
    await tx.wait();
  });

  it("test moveTo (first jump)", async function () {
    const account2 = await mopnerc6551accountproxy.computeAccount(
      mopnerc6551account.address,
      31337,
      testnft.address,
      2,
      0
    );
    accounts.push(account2);
    const account3 = await mopnerc6551accountproxy.computeAccount(
      mopnerc6551account.address,
      31337,
      testnft.address,
      3,
      0
    );
    accounts.push(account3);
    const account4 = await mopnerc6551accountproxy.computeAccount(
      mopnerc6551account.address,
      31337,
      testnft.address,
      4,
      0
    );
    accounts.push(account4);
    const account5 = await mopnerc6551accountproxy.computeAccount(
      mopnerc6551account.address,
      31337,
      testnft.address,
      5,
      0
    );
    accounts.push(account5);
    const account6 = await mopnerc6551accountproxy.computeAccount(
      mopnerc6551account.address,
      31337,
      testnft.address,
      6,
      0
    );
    accounts.push(account6);
    const account7 = await mopnerc6551accountproxy.computeAccount(
      mopnerc6551account.address,
      31337,
      testnft.address,
      7,
      0
    );
    accounts.push(account7);
    const account11 = await mopnerc6551accountproxy.computeAccount(
      mopnerc6551account.address,
      31337,
      testnft1.address,
      0,
      0
    );
    accounts.push(account11);

    const tx = await mopnerc6551accountproxy.multicall([
      mopnerc6551accountproxy.interface.encodeFunctionData("createAccount", [
        mopnerc6551account.address,
        31337,
        testnft.address,
        2,
        0,
        "0x",
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("proxyCall", [
        account2,
        mopn.address,
        0,
        // 0 2
        mopn.interface.encodeFunctionData("moveTo", [10001002, 0]),
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("createAccount", [
        mopnerc6551account.address,
        31337,
        testnft.address,
        3,
        0,
        "0x",
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("proxyCall", [
        account3,
        mopn.address,
        0,
        // 1 2
        mopn.interface.encodeFunctionData("moveTo", [10011002, 0]),
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("createAccount", [
        mopnerc6551account.address,
        31337,
        testnft.address,
        4,
        0,
        "0x",
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("proxyCall", [
        account4,
        mopn.address,
        0,
        // -1 3
        mopn.interface.encodeFunctionData("moveTo", [09991003, 0]),
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("createAccount", [
        mopnerc6551account.address,
        31337,
        testnft.address,
        5,
        0,
        "0x",
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("proxyCall", [
        account5,
        mopn.address,
        0,
        // -1 4
        mopn.interface.encodeFunctionData("moveTo", [09991004, 0]),
      ]),
    ]);
    await tx.wait();

    const tx1 = await mopnerc6551accountproxy.multicall([
      mopnerc6551accountproxy.interface.encodeFunctionData("createAccount", [
        mopnerc6551account.address,
        31337,
        testnft.address,
        6,
        0,
        "0x",
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("proxyCall", [
        account6,
        mopn.address,
        0,
        // 0 4
        mopn.interface.encodeFunctionData("moveTo", [10001004, 0]),
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("createAccount", [
        mopnerc6551account.address,
        31337,
        testnft.address,
        7,
        0,
        "0x",
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("proxyCall", [
        account7,
        mopn.address,
        0,
        // 1 3
        mopn.interface.encodeFunctionData("moveTo", [10011003, 0]),
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("createAccount", [
        mopnerc6551account.address,
        31337,
        testnft1.address,
        0,
        0,
        "0x",
      ]),
      mopnerc6551accountproxy.interface.encodeFunctionData("proxyCall", [
        account11,
        mopn.address,
        0,
        // 4 0
        mopn.interface.encodeFunctionData("moveTo", [10041000, 0]),
      ]),
    ]);
    await tx1.wait();

    await new Promise((r) => setTimeout(r, 5000));

    await avatarInfo();
    await collectionInfo();
  });

  it("test transfer account MT", async function () {
    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );

    const account = accounts[0];
    const amount = await mopnmt.balanceOf(account);
    console.log(account, amount);
    const account1Contract = await ethers.getContractAt("MOPNERC6551Account", accounts[0]);
    const tx1 = await account1Contract.executeCall(
      mopnmt.address,
      0,
      mopnmt.interface.encodeFunctionData("transfer", [owner.address, amount])
    );
    await tx1.wait();

    const multi10Tx = await mopnminingData.multicall([
      mopnminingData.interface.encodeFunctionData("redeemAvatarMT", [2]),
      mopnminingData.interface.encodeFunctionData("redeemAvatarMT", [3]),
      mopnminingData.interface.encodeFunctionData("redeemAvatarMT", [4]),
      mopnminingData.interface.encodeFunctionData("redeemAvatarMT", [5]),
      mopnminingData.interface.encodeFunctionData("redeemAvatarMT", [6]),
      mopnminingData.interface.encodeFunctionData("redeemAvatarMT", [7]),
      mopnminingData.interface.encodeFunctionData("redeemAvatarMT", [8]),
      mopnminingData.interface.encodeFunctionData("redeemAvatarMT", [9]),
    ]);
    await multi10Tx.wait();

    await avatarInfo();

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

    const buybombtx = await mopnauctionHouse.buyBomb(10);
    await buybombtx.wait();

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

  // it("test auction land", async function () {
  //   console.log("Current Land round", await auctionHouse.getLandRoundId());
  //   console.log("Current Land price", await auctionHouse.getLandCurrentPrice());

  //   const buylandtx = await auctionHouse.buyLand();
  //   await buylandtx.wait();

  //   console.log("Current Land round", await auctionHouse.getLandRoundId());
  //   console.log("Current Land price", await auctionHouse.getLandCurrentPrice());

  //   console.log(
  //     "wallet balance",
  //     ethers.utils.formatUnits(await mt.balanceOf(owner.address), mtdecimals)
  //   );
  // });

  it("test bomb", async function () {
    await collectionInfo();

    await avatarInfo();

    // -2 3 -1
    const bombTx = await mopn.bomb([testnft1.address, 0], 09981003);
    await bombTx.wait();

    // 0 3 -3
    const bomb1Tx = await mopn.bomb([testnft1.address, 1], 10001003);
    await bomb1Tx.wait();

    await avatarInfo();

    // console.log(
    //   await avatar.callStatic.multicall([
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [0]),
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [1]),
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [2]),
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [3]),
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [4]),
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [5]),
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [6]),
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [7]),
    //     avatar.interface.encodeFunctionData("getAvatarCoordinate", [8]),
    //   ])
    // );

    // const bomb2Tx = await avatar.bomb([testnft.address, 1, testnftproofs, 0, address0], 10041000);
    // await bomb2Tx.wait();

    // await avatarInfo();

    await collectionInfo();

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test stakingMT", async function () {
    const tx1 = await mopngovernance.createCollectionVault(1);
    await tx1.wait();

    const vault1adddress = await mopngovernance.getCollectionVault(1);
    const vault1 = await ethers.getContractAt("MOPNCollectionVault", vault1adddress);

    console.log(await mopnminingData.getCollectionPoint(1));

    const tx2 = await mopnmt.safeTransferFrom(
      owner.address,
      vault1.address,
      ethers.BigNumber.from("2500000000"),
      "0x"
    );
    await tx2.wait();

    console.log(await mopnminingData.getCollectionPoint(1));

    console.log(await mopnminingData.getCollectionPoint(2));

    const tx3 = await mopnmt.safeTransferFrom(
      owner.address,
      mopngovernance.address,
      ethers.BigNumber.from("2500000000"),
      ethers.utils.solidityPack(["address"], [testnft1.address])
    );
    await tx3.wait();

    console.log(await mopnminingData.getCollectionPoint(2));

    const vault2adddress = await mopngovernance.getCollectionVault(2);
    const vault2 = await ethers.getContractAt("MOPNCollectionVault", vault2adddress);
    console.log(await vault2.balanceOf(owner.address));

    console.log("nft offer price", await vault1.getNFTOfferPrice());

    const tx4 = await testnft.approve(vault1.address, 1);
    tx4.wait();

    const tx5 = await vault1.acceptNFTOffer(1);
    tx5.wait();

    await collectionInfo();
  });

  it("test helpers", async function () {
    console.log(await mopndatahelper.getAvatarByAvatarId(1));
    console.log(await mopndatahelper.getCollectionInfo(1));
  });

  it("test additional point", async function () {
    const tx = await mopngovernance.updateWhiteList(
      "0xf7b96589e870e255f819741784ace5931052fa1b5b06217ef70b08fbe39384ab"
    );
    tx.wait();

    const tx1 = await mopn.setCollectionAdditionalNFTPoints(
      "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      50000,
      ["0x53a9e4f3b38530562374c1fc967127d634f9de0d42fe6b4a9d3c3cc6203e14d5"]
    );
    tx1.wait();

    await collectionInfo();
  });

  // it("test owner proxy", async function () {
  //   const tx1 = await nftownerproxy.registerProxy(
  //     testnft.address,
  //     1,
  //     owner1.address,
  //     Math.floor(Date.now() / 1000) + 86400
  //   );
  //   await tx1.wait();
  // });

  const avatarInfo = async () => {
    console.log("total Point", (await mopnData.TotalNFTPoints()).toString());
    for (const account of accounts) {
      console.log(
        "account",
        account,
        "collection",
        (await mopnData.getAccountCollection(account)).toString(),
        "coordinate",
        await mopnData.getAccountCoordinate(account),
        "getAccountBombUsed",
        (await mopnbomb.balanceOf(account, 1)).toString(),
        "getAccountPoint",
        (await mopnData.getAccountTotalNFTPoint(account)).toString(),
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
        "minted avatar number",
        (await mopnData.getCollectionAccountNum(collection)).toString(),
        "on map avatar number",
        (await mopnData.getCollectionOnMapNum(collection)).toString(),
        "collection account points",
        (await mopnData.getCollectionAccountNFTPoints(collection)).toString(),
        "collection points",
        (await mopnData.getCollectionNFTPoints(collection)).toString(),
        "collection additional points",
        (await mopnData.getCollectionAdditionalNFTPoints(collection)).toString()
      );
    }
  };
});
