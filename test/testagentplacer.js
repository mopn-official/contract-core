const hre = require("hardhat");
const { loadFixture, time, mine } = require("@nomicfoundation/hardhat-network-helpers");
const fs = require("fs");
const Table = require("cli-table3");
const { BigNumber } = require("ethers");
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
    mopnmt,
    mopnData,
    mopncollectionVault,
    mopnrental,
    mopnland,
    mopnlandMetaDataRender;
  let owners,
    mtdecimals,
    accounts = [],
    collections = [],
    tiles = {};

  it("deploy one time contracts and params", async function () {
    owners = await hre.ethers.getSigners();
    console.log("owner", owners[0].address);
    console.log("owner1", owners[1].address);

    let promises = [];

    let tx = await hre.ethers.deployContract("ERC6551Registry");
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            erc6551registry = res;
            console.log("ERC6551Registry", erc6551registry.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await hre.ethers.deployContract("TileMath");
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            tileMath = res;
            console.log("TileMath", tileMath.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );
    const tileMathAddress = tx.address;

    tx = await hre.ethers.deployContract("NFTSVG");
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            nftsvg = res;
            console.log("NFTSVG", nftsvg.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );
    const nftsvgAddress = tx.address;

    tx = await hre.ethers.deployContract("NFTMetaData", {
      libraries: {
        NFTSVG: nftsvgAddress,
        TileMath: tileMathAddress,
      },
    });
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            nftmetadata = res;
            console.log("NFTMetaData", nftmetadata.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    await Promise.all(promises);

    testazuki = await hre.ethers.getContractAt(
      "IERC721",
      "0x016db4c041ba5025f71148765491717fc82f82d8"
    );

    testwow = await hre.ethers.getContractAt(
      "IERC721",
      "0x3e0a709ab1fcc275b0490f4b96373cd830ff63b8"
    );
  });

  async function deployAndSetInitialNFTS() {
    let promises = [];

    let tx = await hre.ethers.deployContract("MOPNGovernance");
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            mopngovernance = res;
            console.log("MOPNGovernance", mopngovernance.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );
    const mopngovernanceAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNBomb", [mopngovernanceAddress]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then(async (res) => {
            mopnbomb = res;
            console.log("MOPNBomb", mopnbomb.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await hre.ethers.deployContract("MOPNPoint", [mopngovernanceAddress]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then(async (res) => {
            mopnpoint = res;
            console.log("MOPNPoint", mopnpoint.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await hre.ethers.deployContract("MOPNToken", [mopngovernanceAddress]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then(async (res) => {
            mopnmt = res;
            console.log("MOPNToken", mopnmt.address);
            mtdecimals = await mopnmt.decimals();
            console.log("mtdecimals", mtdecimals);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );
    const mopntokenAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNRental", [mopntokenAddress, erc6551registry.address]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            mopnrental = res;
            console.log("MOPNRental", mopnrental.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );
    const mopnrentalAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNERC6551Account", [
      mopngovernanceAddress,
      mopnrentalAddress,
    ]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            erc6551account = res;
            console.log("MOPNERC6551Account", erc6551account.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );
    const erc6551accountAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNERC6551AccountProxy", [
      mopngovernanceAddress,
      erc6551accountAddress,
    ]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            erc6551accountproxy = res;
            console.log("MOPNERC6551AccountProxy", erc6551accountproxy.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await hre.ethers.deployContract("MOPNERC6551AccountHelper", [mopngovernanceAddress]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            erc6551accounthelper = res;
            console.log("MOPNERC6551AccountHelper", erc6551accounthelper.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    const unixTimeStamp = Math.floor(Date.now() / 1000) - 86000;
    console.log("auction start timestamp", unixTimeStamp);

    tx = await hre.ethers.deployContract("MOPNAuctionHouse", [
      mopngovernanceAddress,
      unixTimeStamp,
    ]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            mopnauctionHouse = res;
            console.log("MOPNAuctionHouse", mopnauctionHouse.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );
    let mopnauctionHouseAddress = tx.address;

    const startBlock = await hre.ethers.provider.getBlockNumber();
    console.log("mopn start block ", startBlock);

    tx = await hre.ethers.deployContract("MOPN", [
      mopngovernanceAddress,
      60000000,
      startBlock,
      50400,
      10000,
      99999,
      5000,
      "0x2a2c1e9f154879c6658877c9b438c978092705a489202f5678dbd468e3544180",
    ]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            mopn = res;
            console.log("MOPN", mopn.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await hre.ethers.deployContract("MOPNData", [mopngovernanceAddress], {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            mopnData = res;
            console.log("MOPNData", mopnData.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await hre.ethers.deployContract("MOPNCollectionVault", [mopngovernanceAddress]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            mopncollectionVault = res;
            console.log("MOPNCollectionVault", mopncollectionVault.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await hre.ethers.deployContract("MOPNLandMetaDataRender", [mopngovernanceAddress], {
      libraries: {
        NFTMetaData: nftmetadata.address,
        TileMath: tileMath.address,
      },
    });
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            mopnlandMetaDataRender = res;
            console.log("MOPNLandMetaDataRender", mopnlandMetaDataRender.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );
    let mopnlandMetaDataRenderAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNLand", [
      unixTimeStamp,
      200000000000000,
      1001,
      owners[0].address,
      mopnlandMetaDataRenderAddress,
      mopnauctionHouseAddress,
    ]);
    promises.push(
      new Promise((resolve, reject) => {
        tx.deployed()
          .then((res) => {
            mopnland = res;
            console.log("MOPNLand ", mopnland.address);
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    await Promise.all(promises);

    promises = [];
    tx = await mopnland.transferOwnership(mopngovernanceAddress);
    promises.push(
      new Promise((resolve, reject) => {
        tx.wait()
          .then(() => {
            console.log("land owner transfered");
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await mopnland.ethMint(5, { value: "1000000000000000000" });
    promises.push(
      new Promise((resolve, reject) => {
        tx.wait()
          .then(() => {
            console.log("5 land minted");
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await mopnbomb.transferOwnership(mopngovernanceAddress);
    promises.push(
      new Promise((resolve, reject) => {
        tx.wait()
          .then(() => {
            console.log("bomb owner transfered");
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await mopngovernance.updateMOPNContracts(
      mopnauctionHouse.address,
      mopn.address,
      mopnbomb.address,
      mopnmt.address,
      mopnpoint.address,
      mopnland.address,
      mopnData.address,
      mopncollectionVault.address,
      mopnrental.address
    );
    promises.push(
      new Promise((resolve, reject) => {
        tx.wait()
          .then(() => {
            console.log("updateMOPNContracts sent");
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await mopngovernance.updateERC6551Contract(
      erc6551registry.address,
      erc6551accountproxy.address,
      erc6551accounthelper.address
    );
    promises.push(
      new Promise((resolve, reject) => {
        tx.wait()
          .then(() => {
            console.log("updateERC6551Contract sent");
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    tx = await mopngovernance.add6551AccountImplementation(erc6551account.address);
    promises.push(
      new Promise((resolve, reject) => {
        tx.wait()
          .then(() => {
            console.log("add6551AccountImplementation sent");
            resolve();
          })
          .catch((err) => {
            console.error(err);
            reject();
          });
      })
    );

    await Promise.all(promises);

    tx = await mopn.collectionWhiteListRegistry("0x016Db4C041bA5025F71148765491717Fc82f82d8", 0, [
      "0xc1f663e50f998d609c80c9e92fab51c8079464aac70bd4b1fd0441186ba62463",
      "0x0993b6e45352fc4ee86456b53f301f554a89d7ee3c4a9a67dfe91316d6d581c7",
      "0x96445c6d18776b38bf6449f1d9236c2f6fe4a3197d396ca6b9318d9895f58c26",
      "0x039eb31152cd2fa23a36b2ed2d343cd698c2c662cb4772fd535609d15f157f8c",
      "0x799dfa8e6e72bb54dfa558bbaf16ebea197d7eff43a9e43a558eb212b728adb0",
      "0xbf9839e8dacd17689f31a365ba675571f3832232db7c5be68798fa49ceb1ef57",
    ]);
    await tx.wait();

    promises = [];
    const coordinates = [
      9991003, 9991002, 10001003, 10001002, 10001001, 10011002, 10011001, 10001000,
    ];

    for (let i = 0; i < 8; i++) {
      if (i == 0) {
        await deployAccountNFT(testazuki.address, i, coordinates[i], 0);
      } else {
        await deployAccountNFT(testazuki.address, i, coordinates[i], 0);
      }
    }

    // await deployAccountNFT(testwow.address, 0, 10000997, 0);
    // await deployAccountNFT(testwow.address, 1, 10000996, 0);

    await avatarInfo();
    await collectionInfo();

    await mineBlock(10000);

    await avatarInfo();
    await collectionInfo();

    await claimAccountsMT();

    await avatarInfo();
    await collectionInfo();
    await showWalletBalance();

    // await buyBombAnddeployAccount(1, testwow.address, 2, 10000998, 0);

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
    console.log(collection1, "vault1", vault1.address);

    console.log("stake 10000MT to vault1");
    const tx2 = await mopnmt.safeTransferFrom(
      owners[0].address,
      vault1.address,
      hre.ethers.BigNumber.from("10000000000"),
      "0x"
    );
    await tx2.wait();
    await showWalletBalance();
    await collectionInfo();

    console.log(
      "vault1 nft offer price",
      hre.ethers.utils.formatUnits(await vault1.getNFTOfferPrice(), mtdecimals)
    );
    const tx4 = await testnft.approve(vault1.address, 1);
    await tx4.wait();

    console.log("accept vault1 nft offer");
    const tx5 = await vault1.acceptNFTOffer(1);
    await tx5.wait();

    await showWalletBalance();
    await collectionInfo();

    console.log("vault1 auction info", await vault1.getAuctionInfo());
    console.log("vault1 auction price", await vault1.getAuctionCurrentPrice());
    const tx6 = await mopnmt.safeTransferFrom(
      owners[0].address,
      vault1.address,
      await vault1.getAuctionCurrentPrice(),
      hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("acceptAuctionBid"))
    );
    await tx6.wait();
    console.log("vault1 auction info", await vault1.getAuctionInfo());

    const vault1vtbalance = await vault1.balanceOf(owners[0].address);
    console.log("vault1 vt balance", vault1vtbalance);
    console.log("vault1 mt balance", await mopnmt.balanceOf(vault1.address));
    const tx7 = await vault1.withdraw(vault1vtbalance - 1);
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
      const hbalance = await mopnmt.balanceOf(account);
      const accountData = await mopn.getAccountData(account);
      table.push([account, accountData.AgentPlacer, accountData.Coordinate, hbalance.toString()]);
    }

    console.log("hardhat TotalMOPNPoint", (await mopn.TotalMOPNPoints()).toString());
    console.log(table.toString());
  };

  const collectionInfo = async () => {
    let table = new Table({
      head: ["Collection", "OnMapNum", "collectionPoint", "balance", "mvtbalance"],
    });
    for (const collection of collections) {
      let mvtbalance = BigNumber.from(0);
      let vaultaddress = await mopngovernance.getCollectionVault(collection);
      if (vaultaddress != hre.ethers.constants.AddressZero) {
        const vault = await hre.ethers.getContractAt("MOPNCollectionVault", vaultaddress);
        mvtbalance = await vault.totalSupply();
      }

      const collectionData = await mopn.getCollectionData(collection);

      table.push([
        collection,
        collectionData.OnMapNftNumber.toString(),
        collectionData.CollectionMOPNPoint.toString(),
        (await mopnmt.balanceOf(await mopngovernance.getCollectionVault(collection)))
          .add(await mopnData.calcCollectionSettledMT(collection))
          .toString(),
        mvtbalance.toString(),
      ]);
    }
    console.log(table.toString());
  };

  const deployAccountBasic = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );
    accounts.push(account);
    let tx = await erc6551registry.createAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0,
      "0x"
      //erc6551account.interface.encodeFunctionData("setOwnershipHostingType", [1]),
    );
    await tx.wait();

    const accountContract = await hre.ethers.getContractAt("MOPNERC6551Account", account);
    tx = await accountContract.execute(
      mopn.address,
      0,
      mopn.interface.encodeFunctionData("moveTo", [
        account,
        coordinate,
        landId,
        await getMoveToTilesAccounts(coordinate),
      ]),
      0
    );
    await tx.wait();

    tiles[coordinate] = account;
  };

  const deployAccountAndMoveTo = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );
    accounts.push(account);
    let tx = await erc6551registry.createAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0,
      "0x"
    );
    await tx.wait();

    tx = await mopn.moveTo(account, coordinate, landId, await getMoveToTilesAccounts(coordinate));
    await tx.wait();

    tiles[coordinate] = account;
  };

  const deployAccountNFT = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );
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
      erc6551accountproxy.address,
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
    tileaccounts[0] = tiles[tileCoordinate]
      ? tiles[tileCoordinate]
      : hre.ethers.constants.AddressZero;
    tileCoordinate++;
    for (let i = 0; i < 18; i++) {
      tileaccounts[i + 1] = tiles[tileCoordinate]
        ? tiles[tileCoordinate]
        : hre.ethers.constants.AddressZero;
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

  const claimAccountMT = async (number) => {
    console.log("claim accounts", [accounts.slice(0, number)]);
    const tx = await mopn.batchClaimAccountMT([accounts.slice(0, number)]);
    await tx.wait();
  };

  const claimAccountsMT = async () => {
    console.log("claim accounts", [accounts.slice(0, 8), accounts.slice(8, 10)]);
    const tx = await mopn.batchClaimAccountMT([accounts.slice(0, 8), accounts.slice(8, 10)]);
    await tx.wait();
  };

  const claimNFTsMT = async () => {
    console.log("claim nfts", collections);
    const tx = await mopn.batchClaimNFTMT(collections, [
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 1, 2],
    ]);
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
        (await mopnmt.balanceOf(owners[i].address)).toString(),
      ]);
    }
    console.log(table.toString());
  };
});
