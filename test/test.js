const { ethers } = require("hardhat");

describe("MOPN", function () {
  let testnft,
    testnft1,
    owner,
    owner1,
    tileMath,
    mopngovernance,
    mopnauctionHouse,
    mopn,
    mopnbomb,
    mopnmap,
    mopnminingData,
    mopncollectionVault,
    mopnmt,
    mtdecimals,
    mopnland,
    mopnlandMetaDataRender,
    mopnbatchhelper,
    mopndatahelper,
    nftownerproxy;

  const testnftproofs = [
    "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
  ];

  const address0 = "0x0000000000000000000000000000000000000000";

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

    const TESTNFT1 = await ethers.getContractFactory("TESTNFT");
    testnft1 = await TESTNFT1.deploy();
    await testnft1.deployed();
    console.log("TESTNFT1 ", testnft1.address);
  });

  it("deploy MOPN contracts", async function () {
    const MOPNGovernance = await ethers.getContractFactory("MOPNGovernance");
    mopngovernance = await MOPNGovernance.deploy();
    await mopngovernance.deployed();
    console.log("MOPNGovernance", mopngovernance.address);

    const unixTimeStamp = Math.floor(Date.now() / 1000) - 73200;

    const AuctionHouse = await ethers.getContractFactory("MOPNAuctionHouse");
    mopnauctionHouse = await AuctionHouse.deploy(
      mopngovernance.address,
      unixTimeStamp,
      unixTimeStamp
    );
    await mopnauctionHouse.deployed();
    console.log("MOPNAuctionHouse", mopnauctionHouse.address);

    console.log("start timestamp", unixTimeStamp);

    const MOPN = await ethers.getContractFactory("MOPN", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    mopn = await MOPN.deploy(mopngovernance.address);
    await mopn.deployed();
    console.log("MOPN", mopn.address);

    const MOPNMap = await ethers.getContractFactory("MOPNMap", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    mopnmap = await MOPNMap.deploy(mopngovernance.address);
    await mopnmap.deployed();
    console.log("MOPNMap", mopnmap.address);

    const MOPNMiningData = await ethers.getContractFactory("MOPNMiningData");
    mopnminingData = await MOPNMiningData.deploy(mopngovernance.address, unixTimeStamp);
    await mopnminingData.deployed();
    console.log("MOPNMiningData", mopnminingData.address);

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
    mopnbomb = await MOPNBomb.deploy();
    await mopnbomb.deployed();
    console.log("MOPNBomb", mopnbomb.address);

    const MOPNToken = await ethers.getContractFactory("MOPNToken");
    mopnmt = await MOPNToken.deploy();
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

    const MOPNDataHelper = await ethers.getContractFactory("MOPNDataHelper", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
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
      mopnmap.address,
      mopnland.address,
      mopnminingData.address,
      mopncollectionVault.address
    );
    await governancesetmopntx.wait();
  });

  it("mint test nfts", async function () {
    let mintnfttx = await testnft.safeMint(owner.address, 8);
    await mintnfttx.wait();
    mintnfttx = await testnft1.safeMint(owner.address, 2);
    await mintnfttx.wait();
  });

  it("test moveTo (first jump)", async function () {
    // 0 1
    let moveToTx = await mopn.moveTo([testnft.address, 0], 10001001, 0, 0);
    await moveToTx.wait();

    // 0 3
    moveToTx = await mopn.moveTo([testnft.address, 1], 10001003, 1, 0);
    await moveToTx.wait();

    // 0 2
    moveToTx = await mopn.moveTo([testnft.address, 2], 10001002, 2, 0);
    await moveToTx.wait();

    // 1 2
    moveToTx = await mopn.moveTo([testnft.address, 3], 10011002, 3, 0);
    await moveToTx.wait();

    // -1 3
    moveToTx = await mopn.moveTo([testnft.address, 4], 09991003, 4, 0);
    await moveToTx.wait();

    // -1 4
    moveToTx = await mopn.moveTo([testnft.address, 5], 09991004, 2, 0);
    await moveToTx.wait();

    // 0 4
    moveToTx = await mopn.moveTo([testnft.address, 6], 10001004, 2, 0);
    await moveToTx.wait();

    // 1 3
    moveToTx = await mopn.moveTo([testnft.address, 7], 10011003, 2, 0);
    await moveToTx.wait();

    // 4 0
    moveToTx = await mopn.moveTo([testnft1.address, 0], 10041000, 0, 0);
    await moveToTx.wait();

    await avatarInfo();

    await new Promise((r) => setTimeout(r, 5000));

    console.log(await mopndatahelper.getCollectionInfo(1));
    console.log(await mopnminingData.calcCollectionMT(1)); getCollectionMOPNPoint getCollectionAvatarMOPNPoint getCollectionPoint 
  });

  it("test redeemAvatarInboxMT", async function () {
    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );

    const redeemMTTx = await mopnminingData.redeemAvatarMT(1);
    await redeemMTTx.wait();

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

    const tx1 = await mopn.setCollectionAdditionalMOPNPoints(
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
    console.log("total Point", (await mopnminingData.getTotalMOPNPoints()).toString());
    for (let i = 1; i <= 10; i++) {
      console.log(
        "avatarId",
        i,
        "COID",
        (await mopn.getAvatarCOID(i)).toString(),
        "coordinate",
        await mopn.getAvatarCoordinate(i),
        "getAvatarBombUsed",
        (await mopn.getAvatarBombUsed(i)).toString(),
        "getAvatarPoint",
        (await mopnminingData.getAvatarMOPNPoint(i)).toString(),
        "getAvatarInboxMT",
        ethers.utils.formatUnits(await mopnminingData.calcAvatarMT(i), mtdecimals)
      );
    }
  };

  const collectionInfo = async () => {
    for (let i = 1; i < 3; i++) {
      const collectionAddress = await mopn.getCollectionContract(i);
      console.log(
        "COID",
        i,
        "collectionAddress",
        collectionAddress,
        "minted avatar number",
        (await mopn.getCollectionAvatarNum(i)).toString(),
        "on map avatar number",
        (await mopn.getCollectionOnMapNum(i)).toString(),
        "collection points",
        (await mopnminingData.getCollectionMOPNPoint(i)).toString(),
        "collection additional points",
        (await mopn.getCollectionAdditionalMOPNPoints(i)).toString()
      );
    }
  };
});
