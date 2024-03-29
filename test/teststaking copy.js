const hre = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const fs = require("fs");

describe("MOPN", function () {
  let erc6551registry, tileMath, testnft, testnft1, nftsvg, nftmetadata;
  let erc6551account,
    erc6551accountproxy,
    erc6551accounthelper,
    mopngovernance,
    mopnauctionHouse,
    mopn,
    mopnbomb,
    mopnpoint,
    mopnmt,
    mopnData,
    mopncollectionVault,
    mopnland,
    mopnlandMetaDataRender;
  let owner,
    owner1,
    mtdecimals,
    accounts = [],
    collections = [];

  it("deploy one time contracts and params", async function () {
    erc6551registry = await hre.ethers.deployContract("ERC6551Registry");
    console.log("ERC6551Registry", erc6551registry.address);

    tileMath = await hre.ethers.deployContract("TileMath");
    await tileMath.deployed();
    console.log("TileMath", tileMath.address);

    nftsvg = await hre.ethers.deployContract("NFTSVG");
    await nftsvg.deployed();
    console.log("NFTSVG", nftsvg.address);

    const NFTMetaData = await hre.ethers.getContractFactory("NFTMetaData", {
      libraries: {
        NFTSVG: nftsvg.address,
        TileMath: tileMath.address,
      },
    });
    nftmetadata = await NFTMetaData.deploy();
    await nftmetadata.deployed();
    console.log("NFTMetaData", nftmetadata.address);

    const TESTNFT = await hre.ethers.getContractFactory("TESTNFT");
    testnft = await TESTNFT.deploy();
    await testnft.deployed();
    console.log("TESTNFT ", testnft.address);
    collections.push(testnft.address);

    const TESTNFT1 = await hre.ethers.getContractFactory("TESTNFT");
    testnft1 = await TESTNFT1.deploy();
    await testnft1.deployed();
    console.log("TESTNFT1 ", testnft1.address);
    collections.push(testnft1.address);

    [owner, owner1] = await hre.ethers.getSigners();
    console.log("owner", owner.address);
    console.log("owner1", owner1.address);
  });

  async function deployAndSetInitialNFTS() {
    const MOPNGovernance = await hre.ethers.getContractFactory("MOPNGovernance");
    mopngovernance = await MOPNGovernance.deploy();
    await mopngovernance.deployed();
    console.log("MOPNGovernance", mopngovernance.address);

    const MOPNERC6551Account = await hre.ethers.getContractFactory("MOPNERC6551Account");
    erc6551account = await MOPNERC6551Account.deploy(mopngovernance.address);
    await erc6551account.deployed();
    console.log("MOPNERC6551Account", erc6551account.address);

    const MOPNERC6551AccountProxy = await hre.ethers.getContractFactory("MOPNERC6551AccountProxy");
    erc6551accountproxy = await MOPNERC6551AccountProxy.deploy(
      mopngovernance.address,
      erc6551account.address
    );
    await erc6551accountproxy.deployed();
    console.log("MOPNERC6551AccountProxy", erc6551accountproxy.address);

    const MOPNERC6551AccountHelper = await hre.ethers.getContractFactory(
      "MOPNERC6551AccountHelper"
    );
    erc6551accounthelper = await MOPNERC6551AccountHelper.deploy(mopngovernance.address);
    await erc6551accounthelper.deployed();
    console.log("MOPNERC6551AccountHelper", erc6551accounthelper.address);

    const unixTimeStamp = Math.floor(Date.now() / 1000) - 86000;
    console.log("start timestamp", unixTimeStamp);

    const AuctionHouse = await hre.ethers.getContractFactory("MOPNAuctionHouse");
    mopnauctionHouse = await AuctionHouse.deploy(
      mopngovernance.address,
      unixTimeStamp,
      unixTimeStamp
    );
    await mopnauctionHouse.deployed();
    console.log("MOPNAuctionHouse", mopnauctionHouse.address);

    const MOPN = await hre.ethers.getContractFactory("MOPN", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    mopn = await MOPN.deploy(mopngovernance.address, 5000000, unixTimeStamp, 604800, 10000, 99999);
    await mopn.deployed();
    console.log("MOPN", mopn.address);

    const MOPNData = await hre.ethers.getContractFactory("MOPNData");
    mopnData = await MOPNData.deploy(mopngovernance.address);
    await mopnData.deployed();
    console.log("MOPNData", mopnData.address);

    const MOPNCollectionVault = await hre.ethers.getContractFactory("MOPNCollectionVault");
    mopncollectionVault = await MOPNCollectionVault.deploy(mopngovernance.address);
    await mopncollectionVault.deployed();
    console.log("MOPNCollectionVault", mopncollectionVault.address);

    const MOPNLandMetaDataRender = await hre.ethers.getContractFactory("MOPNLandMetaDataRender", {
      libraries: {
        NFTMetaData: nftmetadata.address,
        TileMath: tileMath.address,
      },
    });
    mopnlandMetaDataRender = await MOPNLandMetaDataRender.deploy(mopngovernance.address);
    await mopnlandMetaDataRender.deployed();
    console.log("MOPNLandMetaDataRender", mopnlandMetaDataRender.address);

    const MOPNLand = await hre.ethers.getContractFactory("MOPNLand");
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

    mopnbomb = await hre.ethers.deployContract("MOPNBomb", [mopngovernance.address]);
    console.log("MOPNBomb", mopnbomb.address);

    const MOPNPoint = await hre.ethers.getContractFactory("MOPNPoint");
    mopnpoint = await MOPNPoint.deploy(mopngovernance.address);
    await mopnpoint.deployed();
    console.log("MOPNPoint", mopnpoint.address);

    const MOPNToken = await hre.ethers.getContractFactory("MOPNToken");
    mopnmt = await MOPNToken.deploy(mopngovernance.address);
    await mopnmt.deployed();
    console.log("MOPNToken", mopnmt.address);

    mtdecimals = await mopnmt.decimals();
    console.log("mtdecimals", mtdecimals);

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

    const mttransownertx = await mopnmt.transferOwnership(mopngovernance.address);
    await mttransownertx.wait();

    const transownertx = await mopnbomb.transferOwnership(mopngovernance.address);
    await transownertx.wait();

    const landtransownertx = await mopnland.transferOwnership(mopngovernance.address);
    await landtransownertx.wait();

    let mintnfttx = await testnft.safeMint(owner.address, 20);
    await mintnfttx.wait();
    mintnfttx = await testnft1.safeMint(owner.address, 10);
    await mintnfttx.wait();

    const coordinates = [
      9991003, 9991002, 10001003, 10001002, 10001001, 10011002, 10011001, 10001000,
    ];
    for (let i = 0; i < 8; i++) {
      accounts.push(await deployAccount(testnft.address, i, coordinates[i], 0));
    }

    accounts.push(await deployAccount(testnft1.address, 0, 10000997, 0));

    await timeIncrease(1200);

    await claimAccountsMT();
    await showWalletBalance();
  }

  it("test stakingMT", async function () {
    await loadFixture(deployAndSetInitialNFTS);

    const collection1 = collections[0];
    const collection2 = collections[1];

    console.log("create collection", collection1, "vault");
    const tx1 = await mopngovernance.createCollectionVault(collection1);
    await tx1.wait();

    const vault1 = await hre.ethers.getContractAt(
      "MOPNCollectionVault",
      await mopngovernance.getCollectionVault(collection1)
    );
    console.log(collection1, "vault1", vault1.address);
    console.log(collection1, "collectionpoint 1", await mopn.getCollectionMOPNPoint(collection1));

    const tx2 = await mopnmt.safeTransferFrom(
      owner.address,
      vault1.address,
      hre.ethers.BigNumber.from("1500000000"),
      "0x"
    );
    await tx2.wait();

    console.log(
      "vault1 mt balance",
      hre.ethers.utils.formatUnits(await mopnmt.balanceOf(vault1.address), mtdecimals)
    );
    console.log(collection1, "collectionpoint 1", await mopn.getCollectionMOPNPoint(collection1));

    console.log("vault1 nft offer price", await vault1.getNFTOfferPrice());
    const tx4 = await testnft.approve(vault1.address, 1);
    await tx4.wait();

    console.log("accept vault1 nft offer");
    const tx5 = await vault1.acceptNFTOffer(1);
    await tx5.wait();

    console.log("vault1 auction info", await vault1.getAuctionInfo());
    const tx6 = await mopnmt.safeTransferFrom(
      owner.address,
      vault1.address,
      await vault1.getAuctionCurrentPrice(),
      hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("acceptAuctionBid"))
    );
    await tx6.wait();
    console.log("vault1 auction info", await vault1.getAuctionInfo());

    console.log("create collection", collection2, "multi call");
    const tx3 = await mopnmt.multicall([
      mopnmt.interface.encodeFunctionData("createCollectionVault", [collection2]),
      mopnmt.interface.encodeFunctionData("safeTransferFrom", [
        owner.address,
        await mopngovernance.computeCollectionVault(collection2),
        hre.ethers.BigNumber.from("1500000000"),
        "0x",
      ]),
    ]);
    await tx3.wait();

    const vault2 = await hre.ethers.getContractAt(
      "MOPNCollectionVault",
      await mopngovernance.getCollectionVault(collection2)
    );
    console.log(collection2, "vault2", vault2.address);
    console.log("vault2 mt balance", await mopnmt.balanceOf(vault2.address));
    console.log(collection2, "collectionpoint 2", await mopn.getCollectionMOPNPoint(collection2));

    const vault2pmtbalance = await vault2.balanceOf(owner.address);
    console.log("vault2 pmt balance", vault2pmtbalance);
    console.log("vault2 mt balance", await mopnmt.balanceOf(vault2.address));
    const tx7 = await vault2.withdraw(vault2pmtbalance);
    await tx7.wait();

    await collectionInfo();
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
        hre.ethers.utils.formatUnits(await mopnmt.balanceOf(account), mtdecimals)
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

  const deployAccount = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );

    (
      await erc6551accounthelper.multicall([
        erc6551accounthelper.interface.encodeFunctionData("createAccount", [
          erc6551accountproxy.address,
          31337,
          tokenContract,
          tokenId,
          0,
          "0x",
        ]),
        erc6551accounthelper.interface.encodeFunctionData("proxyCall", [
          account,
          mopn.address,
          0,
          // 0 3
          mopn.interface.encodeFunctionData("moveTo", [coordinate, landId]),
        ]),
      ])
    ).wait();

    console.log("token", tokenContract, tokenId, "account deployed", account);
    return account;
  };

  const claimAccountsMT = async () => {
    const tx = await mopnData.batchClaimAccountMT(accounts);
    await tx.wait();
  };

  const timeIncrease = async (seconds) => {
    console.log("increase", seconds, "seconds");
    await time.increase(seconds);
  };

  const showWalletBalance = async () => {
    console.log(
      "wallet balance",
      hre.ethers.utils.formatUnits(await mopnmt.balanceOf(owner.address), mtdecimals)
    );
  };
});
