const { ethers } = require("hardhat");

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
    erc6551accountproxy = await MOPNERC6551AccountProxy.deploy(mopngovernance.address);
    await erc6551accountproxy.deployed();
    console.log("MOPNERC6551AccountProxy", erc6551accountproxy.address);

    const MOPNERC6551AccountHelper = await ethers.getContractFactory("MOPNERC6551AccountHelper");
    erc6551accounthelper = await MOPNERC6551AccountHelper.deploy(mopngovernance.address);
    await erc6551accounthelper.deployed();
    console.log("MOPNERC6551AccountHelper", erc6551accounthelper.address);

    const MOPNERC6551Account = await ethers.getContractFactory("MOPNERC6551Account");
    erc6551account = await MOPNERC6551Account.deploy(mopngovernance.address);
    await erc6551account.deployed();
    console.log("MOPNERC6551Account", erc6551account.address);
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
    const unixTimeStamp = 1683828189; // Math.floor(Date.now() / 1000) - 73200;
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
    mopn = await MOPN.deploy(mopngovernance.address, unixTimeStamp);
    await mopn.deployed();
    console.log("MOPN", mopn.address);

    const MOPNData = await ethers.getContractFactory("MOPNData");
    mopnData = await MOPNData.deploy(mopngovernance.address);
    await mopnData.deployed();
    console.log("MOPNData", mopnData.address);

    const MOPNCollectionVault = await ethers.getContractFactory("MOPNCollectionVault");
    mopncollectionVault = await MOPNCollectionVault.deploy(mopngovernance.address);
    await mopncollectionVault.deployed();
    console.log("MOPNCollectionVault", mopncollectionVault.address);
  });

  it("deploy MOPNLand", async function () {
    const MOPNLand = await ethers.getContractFactory("MOPNLand");
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
      erc6551accountproxy.address,
      erc6551accounthelper.address,
      [erc6551account.address]
    );
    await governanceset6551tx.wait();

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
    const tx = await erc6551registry.createAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      0,
      0,
      erc6551accountproxy.interface.encodeFunctionData("initialize")
    );
    await tx.wait();

    const account = await erc6551registry.account(
      erc6551accountproxy.address,
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

    const accountContractProxy = await ethers.getContractAt("MOPNERC6551AccountProxy", account);
    console.log(await accountContractProxy.implementation());
    console.log(await accountContract.getRentEndTime());

    const tx2 = await accountContract.rentPermit(owner1.address, 86400);
    await tx2.wait();
  });

  it("test settlePerMOPNPointMinted", async function () {
    await new Promise((r) => setTimeout(r, 5000));
    const tx = await mopn.settlePerMOPNPointMinted();
    await tx.wait();

    await new Promise((r) => setTimeout(r, 5000));
    const tx1 = await mopn.settlePerMOPNPointMinted();
    await tx1.wait();
  });
});
