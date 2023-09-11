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
    mopncurverent,
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

    tx = await hre.ethers.deployContract("ERC6551AccountCurveRental", [mopngovernanceAddress]);
    promises.push(new Promise((resolve, reject) => {
      tx.deployed().then((res) => {
        mopncurverent = res;
        console.log("ERC6551AccountCurveRental", mopncurverent.address);
        resolve();
      }).catch((err) => {
        console.error(err);
        reject();
      })
    }))
    const curverentAddress = tx.address;

    tx = await hre.ethers.deployContract("MOPNERC6551Account", [mopngovernanceAddress, curverentAddress]);
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

    const unixTimeStamp = Math.floor(Date.now() / 1000) - 86000;
    console.log("auction start timestamp", unixTimeStamp);

    tx = await hre.ethers.deployContract("MOPNAuctionHouse", [
      mopngovernanceAddress,
      unixTimeStamp,
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
      mopncurverent.address
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

    promises = [];
    const coordinates = [
      9991003, 9991002, 10001003, 10001002, 10001001, 10011002, 10011001, 10001000,
    ];

    await deployAccountBasic(testnft1.address, 0, 10000997, 0);
    await deploySimulatorAccount(testnft1.address, 0, 10000997, 0);

    for (let i = 0; i < 8; i++) {
      if (i == 0) {
        await deployAccountNFT(testnft.address, i, coordinates[i], 0);
      } else {
        await deployAccountNFT(testnft.address, i, coordinates[i], 0);
      }

      await deploySimulatorAccount(testnft.address, i, coordinates[i], 0);
    }

    await deployAccountCurveRent(testnft1.address, 1, 10000996, 0);
    await deploySimulatorAccount(testnft1.address, 1, 10000996, 0);

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

  it("test move", async function () {
    await loadFixture(deployAndSetInitialNFTS);

    const txmove = await mopn.moveToByOwner(
      accounts[7], 9991001, 0, await getMoveToTilesAccounts(9991001)
    );
    await mineBlock(1);
    await txmove.wait();
    await mopnsimulator.moveTo(accounts[7], collections[0], 9991001);

    await avatarInfo();
    await collectionInfo();

  });

  // it("test stakingMT", async function () {
  //   await loadFixture(deployAndSetInitialNFTS);

  //   const collection1 = collections[0];
  //   const collection2 = collections[1];

  //   console.log("create collection", collection1, "vault");
  //   const tx1 = await mopngovernance.createCollectionVault(collection1);
  //   await mineBlock(1);
  //   await tx1.wait();
  //   const vault1 = await hre.ethers.getContractAt(
  //     "MOPNCollectionVault",
  //     await mopngovernance.getCollectionVault(collection1)
  //   );
  //   console.log(collection1, "vault1", vault1.address);
  //   await collectionInfo();

  //   const tx2 = await mopnmt.safeTransferFrom(
  //     owner.address,
  //     vault1.address,
  //     hre.ethers.BigNumber.from("1500000000"),
  //     "0x"
  //   );
  //   await mineBlock(1);
  //   await tx2.wait();
  //   await mopnsimulator.stakeMT(owner.address, collection1, 1500000000);

  //   await collectionInfo();

  //   // console.log("vault1 nft offer price", await vault1.getNFTOfferPrice());
  //   // const tx4 = await testnft.approve(vault1.address, 1);
  //   // await mineBlock(1);
  //   // await tx4.wait();

  //   // console.log("accept vault1 nft offer");
  //   // const tx5 = await vault1.acceptNFTOffer(1);
  //   // await mineBlock(1);
  //   // await tx5.wait();

  //   // console.log("vault1 auction info", await vault1.getAuctionInfo());
  //   // const tx6 = await mopnmt.safeTransferFrom(
  //   //   owner.address,
  //   //   vault1.address,
  //   //   await vault1.getAuctionCurrentPrice(),
  //   //   hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("acceptAuctionBid"))
  //   // );
  //   // await mineBlock(1);
  //   // await tx6.wait();
  //   // console.log("vault1 auction info", await vault1.getAuctionInfo());

  //   console.log("create collection", collection2, "multi call");
  //   const tx3 = await mopnmt.multicall([
  //     mopnmt.interface.encodeFunctionData("createCollectionVault", [collection2]),
  //     mopnmt.interface.encodeFunctionData("safeTransferFrom", [
  //       owner.address,
  //       await mopngovernance.computeCollectionVault(collection2),
  //       hre.ethers.BigNumber.from("1500000000"),
  //       "0x",
  //     ]),
  //   ]);
  //   await mineBlock(1);
  //   await tx3.wait();
  //   await mopnsimulator.stakeMT(owner.address, collection2, 1500000000);

  //   await collectionInfo();

  //   const vault2 = await hre.ethers.getContractAt(
  //     "MOPNCollectionVault",
  //     await mopngovernance.getCollectionVault(collection2)
  //   );
  //   console.log(collection2, "vault2", vault2.address);

  //   const vault2pmtbalance = await vault2.balanceOf(owner.address);
  //   const tx7 = await vault2.withdraw(vault2pmtbalance);
  //   await mineBlock(1);
  //   await tx7.wait();
  //   await mopnsimulator.unstakeMT(owner.address, collection2, vault2pmtbalance);

  //   await collectionInfo();
  // });

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
      erc6551account.interface.encodeFunctionData("setOwnerHosting", [hre.ethers.constants.AddressZero]),
    );
    mineBlock(1);
    await tx.wait();

    const accountContract = await hre.ethers.getContractAt("MOPNERC6551Account", account);
    tx = await accountContract.executeCall(
      mopn.address,
      0,
      mopn.interface.encodeFunctionData("moveTo", [coordinate, landId, await getMoveToTilesAccounts(coordinate)])
    );
    mineBlock(1);
    await tx.wait();

    tiles[coordinate] = account;
  };

  const deployAccountMOPN = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );
    accounts.push(account);
    const tx = await mopn.multicall([
      mopn.interface.encodeFunctionData("createAccount", [
        erc6551accountproxy.address,
        31337,
        tokenContract,
        tokenId,
        0,
        "0x"
        //erc6551account.interface.encodeFunctionData("setOwnerHosting", [hre.ethers.constants.AddressZero]),
      ]),
      mopn.interface.encodeFunctionData("moveToByOwner", [
        account, coordinate, landId, await getMoveToTilesAccounts(coordinate)
      ]),
    ]);
    mineBlock(1);
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
    const tx = await mopn.moveToNFT(
      tokenContract,
      tokenId,
      coordinate,
      landId,
      await getMoveToTilesAccounts(coordinate),
      erc6551account.interface.encodeFunctionData("setOwnerHosting", [hre.ethers.constants.AddressZero]),
    );
    mineBlock(1);
    await tx.wait();

    tiles[coordinate] = account;
  };

  const deployAccountCurveRent = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );
    accounts.push(account);
    const tx = await mopncurverent.rentNFT(tokenContract,
      tokenId, 100000, { value: "1000000000000000000" });

    mineBlock(1);
    await tx.wait();

    const movetx = await mopn.moveToByOwner(account, coordinate, landId, await getMoveToTilesAccounts(coordinate));
    mineBlock(1);
    await movetx.wait();

    tiles[coordinate] = account;
  };

  const deploySimulatorAccount = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );
    await mopnsimulator.moveTo(account, tokenContract, coordinate);
  };

  const deployAccountHelperMulticallParams = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await erc6551accounthelper.computeAccount(
      erc6551accountproxy.address,
      31337,
      tokenContract,
      tokenId,
      0
    );
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
    const tx = await mopn.batchClaimAccountMT([[accounts[0]], accounts.slice(1, 8)]);
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
