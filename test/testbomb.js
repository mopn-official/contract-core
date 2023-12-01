const hre = require("hardhat");
const { loadFixture, mine } = require("@nomicfoundation/hardhat-network-helpers");
const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const fs = require("fs");
const Table = require("cli-table3");
const { ZeroAddress, formatUnits, keccak256, toUtf8Bytes } = require("ethers");
const MOPNMath = require("../src/simulator/MOPNMath");

describe("MOPN", function () {
  let erc6551registry, tileMath, nftsvg, nftmetadata, testazuki, testwow, testpunk;
  let erc6551account,
    erc6551accountproxy,
    erc6551accounthelper,
    mopngovernance,
    mopnauctionHouse,
    mopn,
    mopnbomb,
    mopnpoint,
    mopntoken,
    mopnData,
    mopncollectionVault,
    mopnland,
    mopnlandMetaDataRender;
  let owners,
    owner,
    mtdecimals,
    accounts = [],
    collections = [],
    tiles = {};

  it("deploy one time contracts and params", async function () {
    await helpers.impersonateAccount("0x3FFE98b5c1c61Cc93b684B44aA2373e1263Dd4A4");
    owner = await hre.ethers.getSigner("0x3FFE98b5c1c61Cc93b684B44aA2373e1263Dd4A4");
    console.log("owner", owner.address);
    owners = await hre.ethers.getSigners();
    console.log("owner0", owners[0].address);
    console.log("owner1", owners[1].address);

    erc6551registry = await hre.ethers.deployContract("ERC6551Registry");
    await erc6551registry.waitForDeployment();
    console.log("ERC6551Registry", await erc6551registry.getAddress());

    tileMath = await hre.ethers.deployContract("TileMath");
    await tileMath.waitForDeployment();
    console.log("TileMath", await tileMath.getAddress());

    nftsvg = await hre.ethers.deployContract("NFTSVG");
    await nftsvg.waitForDeployment();
    console.log("NFTSVG", await nftsvg.getAddress());

    nftmetadata = await hre.ethers.deployContract("NFTMetaData", {
      libraries: {
        NFTSVG: await nftsvg.getAddress(),
        TileMath: await tileMath.getAddress(),
      },
    });
    await nftmetadata.waitForDeployment();
    console.log("NFTMetaData", await nftmetadata.getAddress());

    testazuki = await hre.ethers.getContractAt(
      "IERC721",
      "0x82C46C4EA58B7D6D87704ecD459ee9EfBf458B26"
    );

    testwow = await hre.ethers.getContractAt(
      "IERC721",
      "0x0f25e56443330242F3a70dC101D1Cd42bd12F629"
    );

    testpunk = await hre.ethers.deployContract("CryptoPunksMarket");
    await testpunk.waitForDeployment();
    console.log("CryptoPunksMarket", await testpunk.getAddress());
  });

  async function deployAndSetInitialNFTS() {
    mopngovernance = await hre.ethers.deployContract("MOPNGovernance");
    await mopngovernance.waitForDeployment();
    console.log("MOPNGovernance", await mopngovernance.getAddress());

    mopnbomb = await hre.ethers.deployContract("MOPNBomb", [await mopngovernance.getAddress()]);
    await mopnbomb.waitForDeployment();
    console.log("MOPNBomb", await mopnbomb.getAddress());

    mopnpoint = await hre.ethers.deployContract("MOPNPoint", [await mopngovernance.getAddress()]);
    await mopnpoint.waitForDeployment();
    console.log("MOPNPoint", await mopnpoint.getAddress());

    mopntoken = await hre.ethers.deployContract("MOPNToken", [await mopngovernance.getAddress()]);
    await mopntoken.waitForDeployment();
    console.log("MOPNToken", await mopntoken.getAddress());
    mtdecimals = await mopntoken.decimals();
    console.log("mtdecimals", mtdecimals);

    erc6551account = await hre.ethers.deployContract("MOPNERC6551Account", [
      await mopngovernance.getAddress(),
    ]);
    await erc6551account.waitForDeployment();
    console.log("MOPNERC6551Account", await erc6551account.getAddress());

    erc6551accountproxy = await hre.ethers.deployContract("MOPNERC6551AccountProxy", [
      await mopngovernance.getAddress(),
      await erc6551account.getAddress(),
    ]);
    await erc6551accountproxy.waitForDeployment();
    console.log("MOPNERC6551AccountProxy", await erc6551accountproxy.getAddress());

    erc6551accounthelper = await hre.ethers.deployContract("MOPNERC6551AccountHelper", [
      await mopngovernance.getAddress(),
    ]);
    await erc6551accounthelper.waitForDeployment();
    console.log("MOPNERC6551AccountHelper", await erc6551accounthelper.getAddress());

    const startBlock = await hre.ethers.provider.getBlockNumber();
    console.log("mopn start block ", startBlock);

    mopnauctionHouse = await hre.ethers.deployContract("MOPNAuctionHouse", [
      await mopngovernance.getAddress(),
      startBlock,
    ]);
    await mopnauctionHouse.waitForDeployment();
    console.log("MOPNAuctionHouse", await mopnauctionHouse.getAddress());

    mopn = await hre.ethers.deployContract("MOPN", [
      await mopngovernance.getAddress(),
      startBlock,
      "0x4968379e63cd07ec65d2bcb3092d121e5f533c4c864b3d3a1ce197384f3466a1",
    ]);
    await mopn.waitForDeployment();
    console.log("MOPN", await mopn.getAddress());

    mopnData = await hre.ethers.deployContract("MOPNData", [await mopngovernance.getAddress()], {
      libraries: {
        TileMath: await tileMath.getAddress(),
      },
    });
    await mopnData.waitForDeployment();
    console.log("MOPNData", await mopnData.getAddress());

    mopncollectionVault = await hre.ethers.deployContract("MOPNCollectionVault", [
      await mopngovernance.getAddress(),
    ]);
    await mopncollectionVault.waitForDeployment();
    console.log("MOPNCollectionVault", await mopncollectionVault.getAddress());

    mopnlandMetaDataRender = await hre.ethers.deployContract(
      "MOPNLandMetaDataRender",
      [await mopngovernance.getAddress()],
      {
        libraries: {
          NFTMetaData: await nftmetadata.getAddress(),
          TileMath: await tileMath.getAddress(),
        },
      }
    );
    await mopnlandMetaDataRender.waitForDeployment();
    console.log("MOPNLandMetaDataRender", await mopnlandMetaDataRender.getAddress());

    const unixTimeStamp = Math.floor(Date.now() / 1000) - 86000;
    console.log("auction start timestamp", unixTimeStamp);
    mopnland = await hre.ethers.deployContract("MOPNLand", [
      1,
      200000000000000,
      1001,
      owners[0].address,
      await mopnlandMetaDataRender.getAddress(),
      await mopnauctionHouse.getAddress(),
    ]);
    await mopnland.waitForDeployment();
    console.log("MOPNLand", await mopnland.getAddress());

    promises = [];
    let tx;

    tx = await mopnland.transferOwnership(await mopngovernance.getAddress());
    await tx.wait();
    console.log("land owner transfered");

    tx = await mopnland.ethMint(5, { value: "1000000000000000000" });
    await tx.wait();
    console.log("5 land minted");

    tx = await mopnbomb.transferOwnership(await mopngovernance.getAddress());
    await tx.wait();
    console.log("bomb owner transfered");

    tx = await mopngovernance.updateMOPNContracts(
      await mopnauctionHouse.getAddress(),
      await mopn.getAddress(),
      await mopnbomb.getAddress(),
      await mopntoken.getAddress(),
      await mopnpoint.getAddress(),
      await mopnland.getAddress(),
      await mopnData.getAddress(),
      await mopncollectionVault.getAddress()
    );
    await tx.wait();
    console.log("updateMOPNContracts sent");

    tx = await mopngovernance.updateERC6551Contract(
      await erc6551registry.getAddress(),
      await erc6551accountproxy.getAddress(),
      await erc6551accounthelper.getAddress()
    );
    await tx.wait();
    console.log("updateERC6551Contract sent");

    tx = await mopngovernance.add6551AccountImplementation(await erc6551account.getAddress());
    await tx.wait();
    console.log("add6551AccountImplementation sent");

    collections[0] = "0x82C46C4EA58B7D6D87704ecD459ee9EfBf458B26";
    collections[1] = "0x0f25e56443330242F3a70dC101D1Cd42bd12F629";
    collections[2] = "0x4dEE0017ade1484D203C7CBE32f3BB79aEd7F66A";

    tx = await mopn.collectionWhiteListRegistry(collections[0], 0, [
      "0x6a31284f78921fe2bc680cbf710906cc1bc515058a0038903f189ec6f5698dc9",
      "0x0907015a50d51d0f9a6070a67ed26318352c25074e1cc5f71f632b21b1f4fac5",
      "0xd8794106cc4e2ec3201a47d64290c81fcf57e97e12d231da28ac185fc7a9f462",
    ]);
    await tx.wait();
    console.log("collectionWhiteListRegistry Azuki sent");

    tx = await mopn.collectionWhiteListRegistry(collections[1], 0, [
      "0x8177ba6b397bfada0d305528b2c203a70dcdce62a6bc6c7808a04d60e5ccb450",
      "0x85ab1964779fd84cf99c7726094e070951483466963ae0440de4c13afa867805",
      "0xd8794106cc4e2ec3201a47d64290c81fcf57e97e12d231da28ac185fc7a9f462",
    ]);
    await tx.wait();
    console.log("collectionWhiteListRegistry Doodles sent");

    tx = await mopn.collectionWhiteListRegistry(collections[2], 0, [
      "0x6cebad840d832969075216c8907f6a768adf9cf36698dcc3ef01a547ebaa5303",
      "0x0907015a50d51d0f9a6070a67ed26318352c25074e1cc5f71f632b21b1f4fac5",
      "0xd8794106cc4e2ec3201a47d64290c81fcf57e97e12d231da28ac185fc7a9f462",
    ]);
    await tx.wait();
    console.log("collectionWhiteListRegistry punks sent");

    tx = await testpunk.allInitialOwnersAssigned();
    await tx.wait();

    tx = await testpunk.getPunk(0);
    await tx.wait();

    tx = await testpunk.getPunk(1);
    await tx.wait();

    tx = await testpunk.getPunk(2);
    await tx.wait();

    tx = await testpunk.getPunk(3);
    await tx.wait();

    // tx = await mopntoken.mint(owners[0].address, "1000000000000");
    // await tx.wait();

    promises = [];
    const coordinates = [
      9991003, 9991002, 10001003, 10001002, 10001001, 10011002, 10011001, 10001000,
    ];

    for (let i = 0; i < 8; i++) {
      if (i == 0) {
        await deployAccountNFT(await testazuki.getAddress(), i, coordinates[i], 0);
      } else {
        await deployAccountNFT(await testazuki.getAddress(), i, coordinates[i], 0);
      }
    }

    await deployAccountNFT(await testpunk.getAddress(), 0, 10000997, 0);
    await deployAccountNFT(await testpunk.getAddress(), 1, 10000996, 0);

    await avatarInfo();
    await collectionInfo();

    await mineBlock(10000);

    await avatarInfo();
    await collectionInfo();

    await claimAccountsMT();

    await avatarInfo();
    await collectionInfo();
    await showWalletBalance();

    await buyBombAnddeployAccount(1, await testpunk.getAddress(), 2, 10000998, 0);

    await avatarInfo();
    await collectionInfo();
    await showWalletBalance();
  }

  it("test bomb", async function () {
    await loadFixture(deployAndSetInitialNFTS);

    let tx;
    // tx = await mopntoken.mint(owners[0].address, "1000000000000");
    // await tx.wait();

    console.log("bomb price", await mopnauctionHouse.getBombCurrentPrice());
    console.log("bomb QAct", await mopnauctionHouse.getQAct());
    console.log("bomb QActInfo", await mopnauctionHouse.getQActInfo());

    tx = await mopnauctionHouse.buyBomb(10);

    console.log("bomb price", await mopnauctionHouse.getBombCurrentPrice());
    console.log("bomb QAct", await mopnauctionHouse.getQAct());
    console.log("bomb QActInfo", await mopnauctionHouse.getQActInfo());

    mineBlock(300);

    tx = await mopnauctionHouse.buyBomb(10);

    console.log("bomb price", await mopnauctionHouse.getBombCurrentPrice());
    console.log("bomb QAct", await mopnauctionHouse.getQAct());
    console.log("bomb QActInfo", await mopnauctionHouse.getQActInfo());

    mineBlock(150);

    tx = await mopnauctionHouse.buyBomb(10);

    console.log("bomb price", await mopnauctionHouse.getBombCurrentPrice());
    console.log("bomb QAct", await mopnauctionHouse.getQAct());
    console.log("bomb QActInfo", await mopnauctionHouse.getQActInfo());

    mineBlock(300);

    tx = await mopnauctionHouse.buyBomb(10);

    console.log("bomb price", await mopnauctionHouse.getBombCurrentPrice());
    console.log("bomb QAct", await mopnauctionHouse.getQAct());
    console.log("bomb QActInfo", await mopnauctionHouse.getQActInfo());

    mineBlock(6600);

    tx = await mopnauctionHouse.buyBomb(10);

    console.log("bomb price", await mopnauctionHouse.getBombCurrentPrice());
    console.log("bomb QAct", await mopnauctionHouse.getQAct());
    console.log("bomb QActInfo", await mopnauctionHouse.getQActInfo());
  });

  const avatarInfo = async () => {
    let table = new Table({
      head: ["Account", "AgentPlacer", "coordinate", "balance"],
    });

    for (const account of accounts) {
      const hbalance = await mopntoken.balanceOf(account);
      const accountData = await mopn.getAccountData(account);
      table.push([
        account,
        accountData.AgentPlacer,
        accountData.Coordinate.toString(),
        hbalance.toString(),
      ]);
    }

    console.log("hardhat TotalMOPNPoint", (await mopn.TotalMOPNPoints()).toString());
    console.log(table.toString());
  };

  const collectionInfo = async () => {
    let table = new Table({
      head: ["Collection", "OnMapNum", "collectionPoint", "balance", "mvtbalance"],
    });
    for (const collection of collections) {
      let mvtbalance = 0n;
      let vaultaddress = await mopngovernance.getCollectionVault(collection);
      if (vaultaddress != ZeroAddress) {
        const vault = await hre.ethers.getContractAt("MOPNCollectionVault", vaultaddress);
        mvtbalance = await vault.totalSupply();
      }

      const collectionData = await mopn.getCollectionData(collection);

      table.push([
        collection,
        collectionData.OnMapNftNumber.toString(),
        collectionData.CollectionMOPNPoint.toString(),
        (
          (await mopntoken.balanceOf(await mopngovernance.getCollectionVault(collection))) +
          (await mopnData.calcCollectionSettledMT(collection))
        ).toString(),
        mvtbalance.toString(),
      ]);
    }
    console.log(table.toString());
  };

  const deployAccountNFT = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      await erc6551accountproxy.getAddress(),
      31337,
      tokenContract,
      tokenId,
      0
    );
    console.log("account move", account);
    accounts.push(account);
    const tx = await mopn
      .connect(owners[1])
      .moveToNFT(
        tokenContract,
        tokenId,
        coordinate,
        landId,
        await getMoveToTilesAccounts(coordinate),
        "0x"
      );
    await tx.wait();

    tiles[coordinate] = account;
  };

  const buyBombAnddeployAccount = async (amount, tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      await erc6551accountproxy.getAddress(),
      31337,
      tokenContract,
      tokenId,
      0
    );
    accounts.push(account);

    const bombprice = await mopnauctionHouse.getBombCurrentPrice();
    console.log("bomb price", bombprice);

    let tx;
    //  tx = await mopnauctionHouse.buyBomb(1);
    // await tx.wait();

    // tx = await mopnmt.safeTransferFrom(
    //   owners[0].address,
    //   mopnauctionHouse.address,
    //   bombprice,
    //   hre.ethers.utils.solidityPack(["uint256", "uint256"], [1, 1])
    // );
    // await tx.wait();

    // tx = await mopn.moveToNFT(
    //   tokenContract,
    //   tokenId,
    //   coordinate,
    //   landId,
    //   await getMoveToTilesAccounts(coordinate),
    //   "0x"
    // );
    // await tx.wait();

    tx = await mopn.multicall([
      mopn.interface.encodeFunctionData("buyBomb", [amount]),
      mopn.interface.encodeFunctionData("moveToNFT", [
        tokenContract,
        tokenId,
        coordinate,
        landId,
        await getMoveToTilesAccounts(coordinate),
        "0x",
      ]),
    ]);
    await tx.wait();

    tiles[coordinate] = account;
  };

  const getMoveToTilesAccounts = async (tileCoordinate) => {
    let tileaccounts = [];
    tileaccounts[0] = tiles[tileCoordinate] ? tiles[tileCoordinate] : ZeroAddress;
    tileCoordinate++;
    for (let i = 0; i < 18; i++) {
      tileaccounts[i + 1] = tiles[tileCoordinate] ? tiles[tileCoordinate] : ZeroAddress;
      if (i == 5) {
        tileCoordinate += 10001;
      } else if (i < 5) {
        tileCoordinate = MOPNMath.neighbor(tileCoordinate, i);
      } else {
        tileCoordinate = MOPNMath.neighbor(tileCoordinate, Math.floor((i - 6) / 2));
      }
    }
    return tileaccounts;
  };

  const claimAccountsMT = async () => {
    console.log("claim accounts", [accounts.slice(0, 8), accounts.slice(8, 10)]);
    const tx = await mopn
      .connect(owner)
      .batchClaimAccountMT([accounts.slice(0, 8), accounts.slice(8, 10)]);
    await tx.wait();
  };

  const mineBlock = async (number) => {
    await mine(number);
    console.log("increase hardhat block to ", await hre.ethers.provider.getBlockNumber());
  };

  const showWalletBalance = async () => {
    let table = new Table({
      head: ["Account", "address", "balance"],
    });
    for (let i = 0; i < owners.length; i++) {
      table.push([
        "owner" + i,
        owners[i].address,
        (await mopntoken.balanceOf(owners[i].address)).toString(),
      ]);
    }
    console.log(table.toString());
  };
});
