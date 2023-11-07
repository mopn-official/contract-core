const hre = require("hardhat");
const { loadFixture, time, mine } = require("@nomicfoundation/hardhat-network-helpers");
const fs = require("fs");
const mopnsimulator = require("../src/simulator/mopn");
const Table = require('cli-table3');
const { BigNumber } = require("ethers");
const MOPNMath = require("../src/simulator/MOPNMath");

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
    mopnownershipbid,
    mopnland,
    mopnlandMetaDataRender;
  let owner,
    owner1,
    mtdecimals,
    accounts = [],
    collections = [],
    tiles = {};

  it("deploy one time contracts and params", async function () {
    await mopnsimulator.reset();

    [owner, owner1] = await hre.ethers.getSigners();
    console.log("owner", owner.address);
    console.log("owner1", owner1.address);

    let promises = [];

    let tx = await hre.ethers.deployContract("ERC6551Registry");
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        erc6551registry = res;
        console.log("ERC6551Registry", erc6551registry.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract("TileMath");
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        tileMath = res;
        console.log("TileMath", tileMath.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))
    const tileMathAddress = tx.address;

    tx = await hre.ethers.deployContract("NFTSVG");
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        nftsvg = res;
        console.log("NFTSVG", nftsvg.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))
    const nftsvgAddress = tx.address;

    tx = await hre.ethers.deployContract("NFTMetaData", {
      libraries: {
        NFTSVG: nftsvgAddress,
        TileMath: tileMathAddress,
      },
    });
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        nftmetadata = res;
        console.log("NFTMetaData", nftmetadata.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract("TESTNFT");
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        testnft = res;
        console.log("TESTNFT", testnft.address);
        collections.push(testnft.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract("TESTNFT");
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        testnft1 = res;
        console.log("TESTNFT1", testnft1.address);
        collections.push(testnft1.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    await mineBlock(1);

    await Promise.all(promises);

    promises = [];

    tx = await testnft.safeMint(owner.address, 20);
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("mint 20", testnft.address, "nft to", owner.address)
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }));
    tx = await testnft1.safeMint(owner.address, 20);
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("mint 20", testnft1.address, "nft to", owner.address)
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }));

    await mineBlock(1);
    await Promise.all(promises);


  });

  async function deployAndSetInitialNFTS() {
    let promises = [];

    let tx = await hre.ethers.deployContract("MOPNGovernance");
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopngovernance = res;
        console.log("MOPNGovernance", mopngovernance.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))
    const mopngovernanceAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNERC6551AccountOwnershipBidding", [mopngovernanceAddress, owner1.address, 1]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopnownershipbid = res;
        console.log("MOPNERC6551AccountOwnershipBidding", mopnownershipbid.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))
    const ownershipbidAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNERC6551Account", [mopngovernanceAddress, ownershipbidAddress, ownershipbidAddress]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        erc6551account = res;
        console.log("MOPNERC6551Account", erc6551account.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))
    const erc6551accountAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNERC6551AccountProxy", [
      mopngovernanceAddress,
      erc6551accountAddress
    ]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        erc6551accountproxy = res;
        console.log("MOPNERC6551AccountProxy", erc6551accountproxy.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract(
      "MOPNERC6551AccountHelper", [mopngovernanceAddress]
    );
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        erc6551accounthelper = res;
        console.log("MOPNERC6551AccountHelper", erc6551accounthelper.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    const unixTimeStamp = Math.floor(Date.now() / 1000) - 43000;
    console.log("auction start timestamp", unixTimeStamp);

    tx = await hre.ethers.deployContract("MOPNAuctionHouse", [
      mopngovernanceAddress,
      50000,
      unixTimeStamp
    ]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopnauctionHouse = res;
        console.log("MOPNAuctionHouse", mopnauctionHouse.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))
    let mopnauctionHouseAddress = tx.address;

    const startBlock = await hre.ethers.provider.getBlockNumber();
    console.log("mopn start block ", startBlock);

    tx = await hre.ethers.deployContract("MOPN", [mopngovernanceAddress, 60000000, startBlock, 50400, 10000, 99999]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopn = res;
        console.log("MOPN", mopn.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract("MOPNData", [mopngovernanceAddress], {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopnData = res;
        console.log("MOPNData", mopnData.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract("MOPNCollectionVault", [mopngovernanceAddress]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopncollectionVault = res;
        console.log("MOPNCollectionVault", mopncollectionVault.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract("MOPNLandMetaDataRender", [mopngovernanceAddress], {
      libraries: {
        NFTMetaData: nftmetadata.address,
        TileMath: tileMath.address,
      },
    });
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopnlandMetaDataRender = res;
        console.log("MOPNLandMetaDataRender", mopnlandMetaDataRender.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))
    let mopnlandMetaDataRenderAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNLand", [
      unixTimeStamp,
      200000000000000,
      1001,
      owner.address,
      mopnlandMetaDataRenderAddress,
      mopnauctionHouseAddress
    ]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopnland = res;
        console.log("MOPNLand ", mopnland.address);
        resolve()
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }));

    tx = await hre.ethers.deployContract("MOPNBomb", [mopngovernanceAddress]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then(async (res) => {
        mopnbomb = res;
        console.log("MOPNBomb", mopnbomb.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract("MOPNPoint", [mopngovernanceAddress]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then(async (res) => {
        mopnpoint = res;
        console.log("MOPNPoint", mopnpoint.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))

    tx = await hre.ethers.deployContract("MOPNToken", [mopngovernanceAddress]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then(async (res) => {
        mopnmt = res;
        console.log("MOPNToken", mopnmt.address);
        mtdecimals = await mopnmt.decimals();
        console.log("mtdecimals", mtdecimals);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      });
    }));

    await mineBlock(1);
    await Promise.all(promises);

    promises = [];
    tx = await mopnland.transferOwnership(mopngovernanceAddress);
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("land owner transfered");
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      });
    }));

    tx = await mopnland.ethMint(5, { value: "1000000000000000000" });
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("5 land minted");
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      });
    }));

    tx = await mopnbomb.transferOwnership(mopngovernanceAddress);
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("bomb owner transfered");
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      });
    }));

    tx = await mopnmt.transferOwnership(mopngovernanceAddress);
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("mt owner transfered");
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      });
    }));

    tx = await mopngovernance.updateMOPNContracts(
      mopnauctionHouse.address,
      mopn.address,
      mopnbomb.address,
      mopnmt.address,
      mopnpoint.address,
      mopnland.address,
      mopnData.address,
      mopncollectionVault.address,
      mopnownershipbid.address
    );
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("updateMOPNContracts sent");
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      });
    }));

    tx = await mopngovernance.updateERC6551Contract(
      erc6551registry.address,
      erc6551accountproxy.address,
      erc6551accounthelper.address
    );
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("updateERC6551Contract sent");
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      });
    }));

    tx = await mopngovernance.add6551AccountImplementation(
      erc6551account.address
    );
    promises.push(new Promise((resolve, reject) => {
      tx.wait().then(() => {
        console.log("add6551AccountImplementation sent");
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      });
    }));

    await mineBlock(1);
    await Promise.all(promises);

    const account2 = await computeAccount(testnft1.address, 2);

    // tx = await mopn.multicall([
    //   mopn.interface.encodeFunctionData("createAccount", [
    //     erc6551accountproxy.address,
    //     31337,
    //     testnft1.address,
    //     2,
    //     0,
    //     "0x"
    //   ]),
    //   mopn.interface.encodeFunctionData("moveToByOwner", [
    //     account2,
    //     9971006,
    //     1,
    //     await getMoveToTilesAccounts(9971006)
    //   ])
    // ]);
    // await mineBlock(1);
    // await tx.wait();
    // tiles[9971006] = account2;

    promises = [];
    const coordinates = [
      10001000,
      10001001,
      10011000,
      10010999,
      10000999,
      9991000,
      9991001,
      10001002,
      10011001,
      10021000,
      10020999,
      10020998,
      10010998,
      10000998,
      9990999,
      9981000,
      9981001,
      9981002,
      9991002,
    ];

    for (let i = 0; i < 3; i++) {
      tx = await erc6551accounthelper.multicall(await deployAccountMulticallParams(testnft.address, i, coordinates[i], 0));
      await mineBlock(1);
      await tx.wait();
      await deploySimulatorAccount(testnft.address, i, coordinates[i], 0);
    }

    await mineBlock(1);

    await avatarInfo();
    await collectionInfo();

    await mineBlock(50);

    await avatarInfo();
    await collectionInfo();

    await mineBlock(100);

    await avatarInfo();
    await collectionInfo();

    await mineBlock(10000);

    await avatarInfo();
    await collectionInfo();

    await mineBlock(40000);

    await avatarInfo();
    await collectionInfo();

    await claimAccountsMT();
    await showWalletBalance();
  }

  it("test bomb", async function () {
    await loadFixture(deployAndSetInitialNFTS);

    const allowanceTx = await mopnmt.approve(
      mopnauctionHouse.address,
      hre.ethers.BigNumber.from("10000000000000000")
    );
    await mineBlock(1);
    await allowanceTx.wait();

    console.log("getBombRound", await mopnauctionHouse.bombRound());
    console.log("getBombCurrentPrice", await mopnauctionHouse.getBombCurrentPrice());

    let buybombtx = await mopnauctionHouse.buyBomb(1);
    await mineBlock(1);
    await buybombtx.wait();

    console.log("getBombRound", await mopnauctionHouse.bombRound());

    buybombtx = await mopnauctionHouse.buyBomb(1);
    await mineBlock(1);
    await buybombtx.wait();

    console.log("getBombRound", await mopnauctionHouse.bombRound());

    // buybombtx = await mopnauctionHouse.buyBomb(1);
    // await mineBlock(1);
    // await buybombtx.wait();

    // console.log("getBombRound", await mopnauctionHouse.bombRound());

    // buybombtx = await mopnauctionHouse.buyBomb(1);
    // await mineBlock(1);
    // await buybombtx.wait();

    // console.log("getBombRound", await mopnauctionHouse.bombRound());

    // buybombtx = await mopnauctionHouse.buyBomb(1);
    // await mineBlock(1);
    // await buybombtx.wait();

    // console.log("getBombRound", await mopnauctionHouse.bombRound());

    // buybombtx = await mopnauctionHouse.buyBomb(1);
    // await mineBlock(1);
    // await buybombtx.wait();

    // console.log("getBombRound", await mopnauctionHouse.bombRound());

    // buybombtx = await mopnauctionHouse.buyBomb(1);
    // await mineBlock(1);
    // await buybombtx.wait();

    // console.log("getBombRound", await mopnauctionHouse.bombRound());

    // buybombtx = await mopnauctionHouse.buyBomb(1);
    // await mineBlock(1);
    // await buybombtx.wait();

    // console.log("getBombRound", await mopnauctionHouse.bombRound());

    // buybombtx = await mopnauctionHouse.buyBomb(1);
    // await mineBlock(1);
    // await buybombtx.wait();

    // console.log("getBombRound", await mopnauctionHouse.bombRound());

    // buybombtx = await mopnauctionHouse.buyBomb(1);
    // await mineBlock(1);
    // await buybombtx.wait();

    // console.log("getBombRound", await mopnauctionHouse.bombRound());

    await avatarInfo();
    await collectionInfo();

    const account = await computeAccount(testnft1.address, 1);

    tx = await mopn.moveToNFT(
      testnft1.address,
      1,
      10001000,
      0,
      await getMoveToTilesAccounts(10001000),
      "0x"
    );
    await mineBlock(1);
    await tx.wait();

    await avatarInfo();
    await collectionInfo();
  });

  const avatarInfo = async () => {
    let table = new Table({
      head: ['Account', 'Collection', 'h coordinate', 's coordinate', 'h balance', 's balance', 'balance diff']
    });

    for (const account of accounts) {
      const simuaccount = await mopnsimulator.db.getAccount(account);
      const hbalance = (await mopnmt.balanceOf(account));
      const sbalance = simuaccount['balance'];
      table.push([
        account,
        simuaccount['collection_address'],
        await mopn.getAccountCoordinate(account),
        simuaccount['coordinate'],
        hbalance.toString(),
        sbalance.toString(),
        hbalance.gt(sbalance) ? hbalance.sub(sbalance).toString() : sbalance.sub(hbalance).toString()
      ]);
    }

    console.log("hardhat TotalMOPNPoint", (await mopn.TotalMOPNPoints()).toString());
    console.log("simulator TotalMOPNPoint", (await mopnsimulator.db.getMiningData("TotalMOPNPoint")).toString());
    console.log(table.toString());
  };

  const collectionInfo = async () => {
    let table = new Table({
      head: [
        'Collection', 'h OnMapNum', 's OnMapNum', 'h collectionPoint',
        's collectionPoint', 'h balance', 's balance', 'h mvtbalance', 's mvtbalance'
      ]
    });
    for (const collection of collections) {
      const simucollection = await mopnsimulator.db.getCollection(collection);
      if (!simucollection) continue;
      let mvtbalance = BigNumber.from(0);
      let vaultaddress = await mopngovernance.getCollectionVault(collection);
      if (vaultaddress != hre.ethers.constants.AddressZero) {
        const vault = await hre.ethers.getContractAt(
          "MOPNCollectionVault",
          vaultaddress
        );
        mvtbalance = await vault.totalSupply();
      }

      table.push([
        collection,
        (await mopn.getCollectionOnMapNum(collection)).toString(),
        simucollection['onMapNum'].toString(),
        (await mopn.getCollectionMOPNPoint(collection)).toString(),
        simucollection['collectionPoint'].toString(),
        (await mopnmt.balanceOf(await mopngovernance.getCollectionVault(collection))).add(await mopnData.calcCollectionSettledMT(collection)).toString(),
        simucollection['balance'].toString(),
        mvtbalance.toString(),
        simucollection['mvtbalance'].toString()
      ]);
    }
    console.log(table.toString());
  };

  const computeAccount = async (tokenContract, tokenId) => {
    return await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );
  }

  const deployAccount = async (tokenContract, tokenId, coordinate, landId) => {
    const tx = await erc6551accounthelper.multicall(await deployAccountMulticallParams(tokenContract, tokenId, coordinate, landId));
    await mineBlock(1);
    await tx.wait();
    await deploySimulatorAccount(tokenContract, tokenId, coordinate, landId);
  };

  const deployAccountMulticallParams = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await computeAccount(tokenContract, tokenId);
    accounts.push(account);

    const res = [
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
        mopn.interface.encodeFunctionData("moveTo", [coordinate, landId, await getMoveToTilesAccounts(coordinate)]),
      ]),
    ];
    tiles[coordinate] = account;
    return res;
  };

  const deploySimulatorAccount = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await computeAccount(tokenContract, tokenId);
    await mopnsimulator.moveTo(account, tokenContract, coordinate);
  };

  const getMoveToTilesAccounts = async (tileCoordinate) => {
    let tileaccounts = [];
    tileaccounts[0] = tiles[tileCoordinate] ? tiles[tileCoordinate] : hre.ethers.constants.AddressZero;
    tileCoordinate++;
    for (let i = 0; i < 18; i++) {
      tileaccounts[i + 1] = tiles[tileCoordinate] ? tiles[tileCoordinate] : hre.ethers.constants.AddressZero;
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
    const tx = await mopn.batchClaimAccountMT([accounts]);
    await mineBlock(1);
    await tx.wait();
    await mopnsimulator.claimAccountsMT(owner.address, accounts);
  };

  const mineBlock = async (number) => {
    await mine(number);
    await mopnsimulator.mine(number);
    await mopnsimulator.payAll();
    console.log("increase hardhat block to ", await hre.ethers.provider.getBlockNumber());
    console.log("increase simulator block to ", await mopnsimulator.getBlockNumber());
  };

  const showWalletBalance = async () => {
    console.log(
      "hardhat wallet balance",
      (await mopnmt.balanceOf(owner.address)).toString()
    );
    const simuaccount = await mopnsimulator.db.getAccount(owner.address);
    console.log("simulator wallet balance", simuaccount['balance']);
  };
});