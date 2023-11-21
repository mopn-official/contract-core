const hre = require("hardhat");
const { loadFixture, mine } = require("@nomicfoundation/hardhat-network-helpers");
const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const fs = require("fs");
const Table = require("cli-table3");
const { ZeroAddress, formatUnits, keccak256, toUtf8Bytes } = require("ethers");
const MOPNMath = require("../src/simulator/MOPNMath");

describe("MOPN", function () {
  let erc6551registry, tileMath, nftsvg, nftmetadata, testazuki, testwow;
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
      60000000,
      startBlock,
      "0xc43ea6b2332e02fa1fe0b50f7ab5c9cff3b7ef8bf6ad7bb97570c3a8c4711e26",
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

    tx = await mopn.collectionWhiteListRegistry(collections[0], 0, [
      "0x74882db2fc8c52e1a83ccbcc351efb82d37d42803f50a771078eb69aac8a6b9e",
      "0x565d5e5a20784c2192fd5f801926b7c52b08573d2fe8458ccf8969e5b4581ce9",
      "0xf7d2a360ca36c546533e951bb50472806e71000bcf23c826c3980d0ce44ecd2f",
      "0xb576db60f1950d3e499e5a3c83d9d6bca2b45302e28f5bfeb28e9414e32fb2dd",
      "0x3cde0dfb246cc3d90328601e821052ead77bc24444ab740a68343e02d342d9ba",
      "0x245ae6b3e3c3733b833cb65e653702faeeaf2a6a86cc2675091858e386bea3d4",
    ]);
    await tx.wait();
    console.log("collectionWhiteListRegistry Azuki sent");

    tx = await mopn.collectionWhiteListRegistry(collections[1], 0, [
      "0xb0b4877790136dd9133e710634ce00a988c2e8faba388f28df838faf7a8c87da",
      "0x9afee0bc7cc23bc497b9dc655be4ecceb3c02d279dbdfeefb88f17a3c8ae311a",
      "0x9834b84c866139a0796098a7b5f63375b4b03025d34e589faf09eaeb3a6b94e2",
      "0xd0bbdf62c754b7c975ad905c418d2538a99b492b63757dde24e4ed087229aefa",
      "0xc194bdb664ed18e5ff5f21332c5d1a5531de78bebecb94248259853c8b74b210",
    ]);
    await tx.wait();
    console.log("collectionWhiteListRegistry Doodles sent");

    tx = await mopntoken.mint(owners[0].address, "1000000000000");
    await tx.wait();

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

    await deployAccountNFT(await testwow.getAddress(), 0, 10000997, 0);
    await deployAccountNFT(await testwow.getAddress(), 1, 10000996, 0);

    await avatarInfo();
    await collectionInfo();

    await mineBlock(10000);

    await avatarInfo();
    await collectionInfo();

    await claimAccountsMT();

    await avatarInfo();
    await collectionInfo();
    await showWalletBalance();

    await buyBombAnddeployAccount(1, await testwow.getAddress(), 2, 10000998, 0);

    await avatarInfo();
    await collectionInfo();
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
    console.log(collection1, "vault1", await vault1.getAddress());

    console.log("stake 10000MT to vault1");
    const tx2 = await mopntoken.safeTransferFrom(
      owners[0].address,
      await vault1.getAddress(),
      10000000000n,
      "0x"
    );
    await tx2.wait();
    await showWalletBalance();
    await collectionInfo();

    console.log("vault1 nft offer price", formatUnits(await vault1.getNFTOfferPrice(), mtdecimals));

    console.log("nft owner", await testazuki.ownerOf(1), "owner1", owner.address);

    const tx4 = await testazuki.connect(owner).approve(await vault1.getAddress(), 1);
    await tx4.wait();

    console.log("accept vault1 nft offer");
    const tx5 = await vault1.connect(owner).acceptNFTOffer(1);
    await tx5.wait();

    await showWalletBalance();
    await collectionInfo();

    console.log("vault1 auction info", await vault1.getAuctionInfo());
    console.log("vault1 auction price", await vault1.getAuctionCurrentPrice());
    const tx6 = await mopntoken.safeTransferFrom(
      owners[0].address,
      await vault1.getAddress(),
      await vault1.getAuctionCurrentPrice(),
      keccak256(toUtf8Bytes("acceptAuctionBid"))
    );
    await tx6.wait();
    console.log("vault1 auction info", await vault1.getAuctionInfo());

    const vault1vtbalance = await vault1.balanceOf(owners[0].address);
    console.log("vault1 vt balance", vault1vtbalance);
    console.log("vault1 mt balance", await mopntoken.balanceOf(await vault1.getAddress()));
    const tx7 = await vault1.withdraw(vault1vtbalance - 1n);
    await tx7.wait();

    await showWalletBalance();
    await collectionInfo();

    // console.log("create collection", collection2, "multi call");
    // const tx3 = await mopnmt.multicall([
    //   mopnmt.interface.encodeFunctionData("createCollectionVault", [collection2]),
    //   mopnmt.interface.encodeFunctionData("safeTransferFrom", [
    //     owner.address,
    //     await mopngovernance.computeCollectionVault(collection2),
    //     hre.ethers.BigNumber.from("10000000000"),
    //     "0x",
    //   ]),
    // ]);
    // await tx3.wait();

    // const vault2 = await hre.ethers.getContractAt(
    //   "MOPNCollectionVault",
    //   await mopngovernance.getCollectionVault(collection2)
    // );
    // console.log(collection2, "vault2", vault2.address);
    // console.log("vault2 mt balance", await mopnmt.balanceOf(vault2.address));
    // console.log(collection2, "collectionpoint 2", await mopn.getCollectionMOPNPoint(collection2));

    // const vault2pmtbalance = await vault2.balanceOf(owner.address);
    // console.log("vault2 pmt balance", vault2pmtbalance);
    // console.log("vault2 mt balance", await mopnmt.balanceOf(vault2.address));
    // const tx7 = await vault2.withdraw(vault2pmtbalance - 1);
    // await tx7.wait();

    mineBlock(100);

    await claimAccountsMT();

    await avatarInfo();
    await collectionInfo();
    await showWalletBalance();
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
        (await mopntoken.balanceOf(await mopngovernance.getCollectionVault(collection))) +
          (await mopnData.calcCollectionSettledMT(collection)).toString(),
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
