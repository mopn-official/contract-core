const { ethers } = require("hardhat");

describe("MOPN", function () {
  let testnft,
    testnft1,
    owner,
    owner1,
    tileMath,
    governance,
    auctionHouse,
    avatar,
    bomb,
    map,
    miningData,
    collectionPoints,
    collectionVault,
    mt,
    mtdecimals,
    land,
    landMetaDataRender,
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
    const Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy();
    await governance.deployed();
    console.log("Governance", governance.address);

    const unixTimeStamp = Math.floor(Date.now() / 1000) - 73200;

    const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
    auctionHouse = await AuctionHouse.deploy(governance.address, unixTimeStamp, unixTimeStamp);
    await auctionHouse.deployed();
    console.log("AuctionHouse", auctionHouse.address);

    console.log("start timestamp", unixTimeStamp);

    const Avatar = await ethers.getContractFactory("Avatar", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    avatar = await Avatar.deploy(governance.address);
    await avatar.deployed();
    console.log("Avatar", avatar.address);

    const Map = await ethers.getContractFactory("Map", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    map = await Map.deploy(governance.address);
    await map.deployed();
    console.log("Map", map.address);

    const MiningData = await ethers.getContractFactory("MiningData");
    miningData = await MiningData.deploy(governance.address, unixTimeStamp);
    await miningData.deployed();
    console.log("MiningData", miningData.address);

    const MOPNCollectionVault = await ethers.getContractFactory("MOPNCollectionVault");
    collectionVault = await MOPNCollectionVault.deploy(governance.address);
    await collectionVault.deployed();
    console.log("MOPNCollectionVault", collectionVault.address);
  });

  it("deploy MOPNLand", async function () {
    const MOPNLand = await ethers.getContractFactory("MOPNLandMirror");
    land = await MOPNLand.deploy();
    await land.deployed();
    console.log("MOPNLand ", land.address);

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

    const LandMetaDataRender = await ethers.getContractFactory("LandMetaDataRender", {
      libraries: {
        NFTMetaData: nftmetadata.address,
        TileMath: tileMath.address,
      },
    });
    landMetaDataRender = await LandMetaDataRender.deploy(governance.address);
    await landMetaDataRender.deployed();
    console.log("LandMetaDataRender", landMetaDataRender.address);

    console.log("mint some land");
    let minpasstx = await land.claim(owner.address, 0);
    await minpasstx.wait();
    minpasstx = await land.claim(owner.address, 100);
    await minpasstx.wait();
  });

  it("deploy Tokens", async function () {
    const Bomb = await ethers.getContractFactory("Bomb");
    bomb = await Bomb.deploy();
    await bomb.deployed();
    console.log("Bomb", bomb.address);

    const MOPNToken = await ethers.getContractFactory("MOPNToken");
    mt = await MOPNToken.deploy();
    await mt.deployed();
    console.log("MOPNToken", mt.address);

    mtdecimals = await mt.decimals();
    console.log("mtdecimals", mtdecimals);
  });

  it("deploy helpers", async function () {
    const MopnBatchHelper = await ethers.getContractFactory("MopnBatchHelper");
    mopnbatchhelper = await MopnBatchHelper.deploy(governance.address);
    await mopnbatchhelper.deployed();
    console.log("MopnBatchHelper", mopnbatchhelper.address);

    const MopnDataHelper = await ethers.getContractFactory("MopnDataHelper", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    mopndatahelper = await MopnDataHelper.deploy(governance.address);
    await mopndatahelper.deployed();
    console.log("MopnDataHelper", mopndatahelper.address);

    // const NFTOwnerProxy = await ethers.getContractFactory("NFTOwnerProxy");
    // nftownerproxy = await NFTOwnerProxy.deploy();
    // await nftownerproxy.deployed();
    // console.log("OwnerProxy", nftownerproxy.address);
  });

  it("transfer contract owners", async function () {
    const mttransownertx = await mt.transferOwnership(governance.address);
    await mttransownertx.wait();

    const transownertx = await bomb.transferOwnership(governance.address);
    await transownertx.wait();

    const landtransownertx = await land.transferOwnership(governance.address);
    await landtransownertx.wait();
  });

  it("update contract attributes", async function () {
    const governancesetroottx = await governance.updateWhiteList(
      "0x8a746c884b5d358e2337e88b5da1afe745ffe4a3a5a378819ec41d0979c9931b"
    );
    await governancesetroottx.wait();

    const governancesetmopntx = await governance.updateMOPNContracts(
      auctionHouse.address,
      avatar.address,
      bomb.address,
      mt.address,
      map.address,
      land.address,
      miningData.address,
      collectionVault.address
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
    let moveToTx = await avatar.moveTo(
      [testnft.address, 0, testnftproofs, 0, address0],
      10001001,
      0,
      0
    );
    await moveToTx.wait();

    // 0 3
    moveToTx = await avatar.moveTo(
      [testnft.address, 1, testnftproofs, 0, address0],
      10001003,
      1,
      0
    );
    await moveToTx.wait();

    // 0 2
    moveToTx = await avatar.moveTo(
      [testnft.address, 2, testnftproofs, 0, address0],
      10001002,
      2,
      0
    );
    await moveToTx.wait();

    // 1 2
    moveToTx = await avatar.moveTo(
      [testnft.address, 3, testnftproofs, 0, address0],
      10011002,
      3,
      0
    );
    await moveToTx.wait();

    // -1 3
    moveToTx = await avatar.moveTo(
      [testnft.address, 4, testnftproofs, 0, address0],
      09991003,
      4,
      0
    );
    await moveToTx.wait();

    // -1 4
    moveToTx = await avatar.moveTo(
      [testnft.address, 5, testnftproofs, 0, address0],
      09991004,
      2,
      0
    );
    await moveToTx.wait();

    // 0 4
    moveToTx = await avatar.moveTo(
      [testnft.address, 6, testnftproofs, 0, address0],
      10001004,
      2,
      0
    );
    await moveToTx.wait();

    // 1 3
    moveToTx = await avatar.moveTo(
      [testnft.address, 7, testnftproofs, 0, address0],
      10011003,
      2,
      0
    );
    await moveToTx.wait();

    // 4 0
    moveToTx = await avatar.moveTo(
      [testnft1.address, 0, testnftproofs, 0, address0],
      10041000,
      0,
      0
    );
    await moveToTx.wait();

    await avatarInfo();

    await new Promise((r) => setTimeout(r, 5000));
  });

  it("test redeemAvatarInboxMT", async function () {
    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mt.balanceOf(owner.address), mtdecimals)
    );

    const redeemMTTx = await miningData.redeemAvatarMT(1);
    await redeemMTTx.wait();

    const multi10Tx = await miningData.multicall([
      miningData.interface.encodeFunctionData("redeemAvatarMT", [2]),
      miningData.interface.encodeFunctionData("redeemAvatarMT", [3]),
      miningData.interface.encodeFunctionData("redeemAvatarMT", [4]),
      miningData.interface.encodeFunctionData("redeemAvatarMT", [5]),
      miningData.interface.encodeFunctionData("redeemAvatarMT", [6]),
      miningData.interface.encodeFunctionData("redeemAvatarMT", [7]),
      miningData.interface.encodeFunctionData("redeemAvatarMT", [8]),
      miningData.interface.encodeFunctionData("redeemAvatarMT", [9]),
    ]);
    await multi10Tx.wait();

    await avatarInfo();

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test auctionHouse", async function () {
    const allowanceTx = await mt.approve(
      auctionHouse.address,
      ethers.BigNumber.from("10000000000000000")
    );
    await allowanceTx.wait();

    console.log("Current Bomb round", await auctionHouse.getBombRoundId());
    console.log("Current Bomb round sold", await auctionHouse.getBombRoundSold());
    console.log(
      "current bomb price",
      ethers.utils.formatUnits(await auctionHouse.getBombCurrentPrice(), mtdecimals)
    );

    const buybombtx = await auctionHouse.buyBomb(10);
    await buybombtx.wait();

    console.log("Current Bomb round", await auctionHouse.getBombRoundId());
    console.log("Current Bomb round sold", await auctionHouse.getBombRoundSold());
    console.log(
      "current bomb price",
      ethers.utils.formatUnits(await auctionHouse.getBombCurrentPrice(), mtdecimals)
    );

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mt.balanceOf(owner.address), mtdecimals)
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
    const bombTx = await avatar.bomb([testnft1.address, 0, testnftproofs, 0, address0], 09981003);
    await bombTx.wait();

    // 0 3 -3
    const bomb1Tx = await avatar.bomb([testnft1.address, 1, testnftproofs, 0, address0], 10001003);
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
      ethers.utils.formatUnits(await mt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test stakingMT", async function () {
    const tx1 = await governance.createCollectionVault(1);
    await tx1.wait();

    const vault1adddress = await governance.getCollectionVault(1);
    const vault1 = await ethers.getContractAt("MOPNCollectionVault", vault1adddress);

    console.log(await miningData.getCollectionPoint(1));

    const tx2 = await mt.safeTransferFrom(
      owner.address,
      vault1.address,
      ethers.BigNumber.from("2500000000"),
      "0x"
    );
    await tx2.wait();

    console.log(await miningData.getCollectionPoint(1));

    console.log(await miningData.getCollectionPoint(2));

    const tx3 = await mt.safeTransferFrom(
      owner.address,
      governance.address,
      ethers.BigNumber.from("2500000000"),
      ethers.utils.solidityPack(["address"], [testnft1.address])
    );
    await tx3.wait();

    console.log(await miningData.getCollectionPoint(2));

    const vault2adddress = await governance.getCollectionVault(2);
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
    console.log("total Point", (await miningData.getTotalNFTPoints()).toString());
    for (let i = 1; i <= 10; i++) {
      console.log(
        "avatarId",
        i,
        "COID",
        (await avatar.getAvatarCOID(i)).toString(),
        "coordinate",
        await avatar.getAvatarCoordinate(i),
        "getAvatarBombUsed",
        (await avatar.getAvatarBombUsed(i)).toString(),
        "getAvatarPoint",
        (await miningData.getAvatarNFTPoint(i)).toString(),
        "getAvatarInboxMT",
        ethers.utils.formatUnits(await miningData.calcAvatarMT(i), mtdecimals)
      );
    }
  };

  const collectionInfo = async () => {
    for (let i = 1; i < 3; i++) {
      const collectionAddress = await avatar.getCollectionContract(i);
      console.log(
        "COID",
        i,
        "collectionAddress",
        collectionAddress,
        "minted avatar number",
        (await avatar.getCollectionAvatarNum(i)).toString(),
        "on map avatar number",
        (await avatar.getCollectionOnMapNum(i)).toString(),
        "collection points",
        (await miningData.getCollectionNFTPoint(i)).toString()
      );
    }
  };
});
