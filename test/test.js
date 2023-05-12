const { ethers } = require("hardhat");

describe("MOPN", function () {
  let testnft,
    testnft1,
    owner,
    tileMath,
    governance,
    auctionHouse,
    avatar,
    map,
    bomb,
    mt,
    mtdecimals,
    land,
    landMetaDataRender;

  const testnftproofs = [
    "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
  ];

  const address0 = "0x0000000000000000000000000000000000000000";

  it("deploy TileMath", async function () {
    [owner] = await ethers.getSigners();

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
    landMetaDataRender = await LandMetaDataRender.deploy();
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
  });

  it("deploy MOPN contracts", async function () {
    const unixTimeStamp = Math.floor(Date.now() / 1000) - 73200;

    const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
    auctionHouse = await AuctionHouse.deploy(unixTimeStamp, unixTimeStamp);
    await auctionHouse.deployed();
    console.log("AuctionHouse", auctionHouse.address);

    console.log(unixTimeStamp);
    console.log(await auctionHouse.gettimestamp());

    console.log("raw data", await auctionHouse.bombRound());

    console.log("roundId", await auctionHouse.getBombRoundId());
    console.log("round start timestamp", await auctionHouse.getBombRoundStartTimestamp());
    console.log("round sold", await auctionHouse.getBombRoundSold());

    const Avatar = await ethers.getContractFactory("Avatar", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    avatar = await Avatar.deploy();
    await avatar.deployed();
    console.log("Avatar", avatar.address);

    const Map = await ethers.getContractFactory("Map", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    map = await Map.deploy(unixTimeStamp);
    await map.deployed();
    console.log("Map", map.address);

    const Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy();
    await governance.deployed();
    console.log("Governance", governance.address);
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
      land.address
    );
    await governancesetmopntx.wait();

    const mapsetgovernancecontracttx = await map.setGovernanceContract(governance.address);
    await mapsetgovernancecontracttx.wait();

    const avatarsetgovernancecontracttx = await avatar.setGovernanceContract(governance.address);
    await avatarsetgovernancecontracttx.wait();

    const auctionHousesetgovernancecontracttx = await auctionHouse.setGovernanceContract(
      governance.address
    );
    await auctionHousesetgovernancecontracttx.wait();

    const LandMetaDataRendersetgovernancecontracttx =
      await landMetaDataRender.setGovernanceContract(governance.address);
    await LandMetaDataRendersetgovernancecontracttx.wait();
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
  });

  it("test redeemAvatarInboxMT", async function () {
    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mt.balanceOf(owner.address), mtdecimals)
    );

    const redeemMTTx = await governance.redeemAvatarInboxMT(1, 0, address0);
    await redeemMTTx.wait();

    const multi10Tx = await governance.multicall([
      governance.interface.encodeFunctionData("redeemAvatarInboxMT", [2, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxMT", [3, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxMT", [4, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxMT", [5, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxMT", [6, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxMT", [7, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxMT", [8, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxMT", [9, 0, address0]),
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

    const buybombtx = await auctionHouse.buyBomb(100);
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

  it("test auction land", async function () {
    console.log("Current Land round", await auctionHouse.getLandRoundId());
    console.log("Current Land price", await auctionHouse.getLandCurrentPrice());

    const buylandtx = await auctionHouse.buyLand();
    await buylandtx.wait();

    console.log("Current Land round", await auctionHouse.getLandRoundId());
    console.log("Current Land price", await auctionHouse.getLandCurrentPrice());

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mt.balanceOf(owner.address), mtdecimals)
    );
  });

  it("test bomb", async function () {
    await collectionInfo();
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

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await mt.balanceOf(owner.address), mtdecimals)
    );
  });

  const avatarInfo = async () => {
    for (let i = 1; i < 10; i++) {
      console.log(
        "avatarId",
        i,
        "COID",
        (await avatar.getAvatarCOID(i)).toString(),
        "coordinate",
        await avatar.getAvatarCoordinate(i),
        "getAvatarBombUsed",
        (await avatar.getAvatarBombUsed(i)).toString(),
        "getAvatarInboxMT",
        ethers.utils.formatUnits(await map.getAvatarInboxMT(i), mtdecimals)
      );
    }
  };

  const collectionInfo = async () => {
    for (let i = 1; i < 3; i++) {
      const collectionAddress = await governance.getCollectionContract(i);
      console.log(
        "COID",
        i,
        "collectionAddress",
        collectionAddress,
        "minted avatar number",
        (await governance.getCollectionAvatarNum(i)).toString(),
        "on map avatar number",
        (await governance.getCollectionOnMapNum(i)).toString()
      );
    }
  };
});
