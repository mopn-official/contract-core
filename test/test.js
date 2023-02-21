const { ethers } = require("hardhat");

describe("MOPN", function () {
  let testnft,
    testnft1,
    tileMath,
    governance,
    arsenal,
    avatar,
    map,
    bomb,
    energy,
    energydecimals,
    passMetaDataRender;

  it("deploy ", async function () {
    const TESTNFT = await ethers.getContractFactory("TESTNFT");
    testnft = await TESTNFT.deploy();
    await testnft.deployed();
    console.log("TESTNFT ", testnft.address);

    const TESTNFT1 = await ethers.getContractFactory("TESTNFT");
    testnft1 = await TESTNFT1.deploy();
    await testnft1.deployed();
    console.log("TESTNFT1 ", testnft1.address);

    const TileMath = await ethers.getContractFactory("TileMath");
    tileMath = await TileMath.deploy();
    await tileMath.deployed();
    console.log("TileMath", tileMath.address);

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

    const Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy(0, false);
    await governance.deployed();
    console.log("Governance", governance.address);

    const Map = await ethers.getContractFactory("Map", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    map = await Map.deploy();
    await map.deployed();
    console.log("Map", map.address);

    const Avatar = await ethers.getContractFactory("Avatar", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    avatar = await Avatar.deploy();
    await avatar.deployed();
    console.log("Avatar", avatar.address);

    const Bomb = await ethers.getContractFactory("Bomb");
    bomb = await Bomb.deploy();
    await bomb.deployed();
    console.log("Bomb", bomb.address);

    const Energy = await ethers.getContractFactory("Energy");
    energy = await Energy.deploy("$Energy", "MOPNE");
    await energy.deployed();
    console.log("Energy", energy.address);

    energydecimals = await energy.decimals();

    const Arsenal = await ethers.getContractFactory("Arsenal");
    arsenal = await Arsenal.deploy();
    await arsenal.deployed();
    console.log("Arsenal", arsenal.address);

    const PassMetaDataRender = await ethers.getContractFactory("PassMetaDataRender", {
      libraries: {
        NFTMetaData: nftmetadata.address,
        TileMath: tileMath.address,
      },
    });
    passMetaDataRender = await PassMetaDataRender.deploy();
    await passMetaDataRender.deployed();
    console.log("PassMetaDataRender", passMetaDataRender.address);

    const energytransownertx = await energy.transferOwnership(governance.address);
    await energytransownertx.wait();

    const transownertx = await bomb.transferOwnership(governance.address);
    await transownertx.wait();

    const governancesetroottx = await governance.updateWhiteList(
      "0x8a746c884b5d358e2337e88b5da1afe745ffe4a3a5a378819ec41d0979c9931b"
    );
    await governancesetroottx.wait();

    const governancesetmopntx = await governance.updateMOPNContracts(
      arsenal.address,
      avatar.address,
      bomb.address,
      energy.address,
      map.address,
      map.address
    );
    await governancesetmopntx.wait();

    const mapsetgovernancecontracttx = await map.setGovernanceContract(governance.address);
    await mapsetgovernancecontracttx.wait();

    const avatarsetgovernancecontracttx = await avatar.setGovernanceContract(governance.address);
    await avatarsetgovernancecontracttx.wait();

    const arsenalsetgovernancecontracttx = await arsenal.setGovernanceContract(governance.address);
    await arsenalsetgovernancecontracttx.wait();

    const passMetaDataRendersetgovernancecontracttx =
      await passMetaDataRender.setGovernanceContract(governance.address);
    await passMetaDataRendersetgovernancecontracttx.wait();
  });

  it("test mint nft", async function () {
    const [owner] = await ethers.getSigners();

    const testnftproofs = [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ];

    const address0 = "0x0000000000000000000000000000000000000000";

    let mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    // const mintTx = await avatar.mintAvatar(testnft.address, 0, testnftproofs, 0, address0);
    // await mintTx.wait();

    // 0 0 0
    // const jumpInTx = await avatar.jumpIn([100010001000, 0, 1, 1, 0, address0]);
    // await jumpInTx.wait();

    const multiTx = await avatar.multicall([
      avatar.interface.encodeFunctionData("mintAvatar", [
        testnft.address,
        0,
        testnftproofs,
        0,
        address0,
      ]),
      avatar.interface.encodeFunctionData("jumpIn", [[10001000, 0, 1, 1, 0, address0]]),
    ]);
    await multiTx.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    // const mintTx1 = await avatar.mintAvatar(testnft.address, 1, testnftproofs, 0, address0);
    // await mintTx1.wait();

    // 0 3 -3
    // const jumpIn1Tx = await avatar.jumpIn([100010030997, 1, 2, 1, 0, address0]);
    // await jumpIn1Tx.wait();

    const multi1Tx = await avatar.multicall([
      avatar.interface.encodeFunctionData("mintAvatar", [
        testnft.address,
        1,
        testnftproofs,
        0,
        address0,
      ]),
      avatar.interface.encodeFunctionData("jumpIn", [[10001003, 1, 2, 1, 0, address0]]),
    ]);
    await multi1Tx.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx2 = await avatar.mintAvatar(testnft.address, 2, testnftproofs, 0, address0);
    await mintTx2.wait();

    // 0 2 -2
    const jumpIn2Tx = await avatar.jumpIn([10001002, 2, 3, 1, 0, address0]);
    await jumpIn2Tx.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx3 = await avatar.mintAvatar(testnft.address, 3, testnftproofs, 0, address0);
    await mintTx3.wait();

    // 1 2 -3
    const jumpIn3Tx = await avatar.jumpIn([10011002, 2, 4, 1, 0, address0]);
    await jumpIn3Tx.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx4 = await avatar.mintAvatar(testnft.address, 4, testnftproofs, 0, address0);
    await mintTx4.wait();

    // -1 3 -2
    const jumpIn4Tx = await avatar.jumpIn([09991003, 2, 5, 1, 0, address0]);
    await jumpIn4Tx.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx5 = await avatar.mintAvatar(testnft.address, 5, testnftproofs, 0, address0);
    await mintTx5.wait();

    // -1 4 -3
    const jumpIn5Tx = await avatar.jumpIn([09991004, 2, 6, 1, 0, address0]);
    await jumpIn5Tx.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx6 = await avatar.mintAvatar(testnft.address, 6, testnftproofs, 0, address0);
    await mintTx6.wait();

    // 0 4 -4
    const jumpIn6Tx = await avatar.jumpIn([10001004, 2, 7, 1, 0, address0]);
    await jumpIn6Tx.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx7 = await avatar.mintAvatar(testnft.address, 7, testnftproofs, 0, address0);
    await mintTx7.wait();

    // 1 3 -4
    const jumpIn7Tx = await avatar.jumpIn([10011003, 2, 8, 1, 0, address0]);
    await jumpIn7Tx.wait();

    mintnfttx = await testnft1.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx8 = await avatar.mintAvatar(testnft1.address, 0, testnftproofs, 0, address0);
    await mintTx8.wait();

    // 4 0 -4
    const jumpIn8Tx = await avatar.jumpIn([10041000, 0, 9, 1, 0, address0]);
    await jumpIn8Tx.wait();

    console.log(await avatar.getAvatarByNFT(testnft.address, 0));
    console.log(await avatar.getAvatarByNFT(testnft.address, 1));
    console.log(await avatar.getAvatarByNFT(testnft.address, 2));
    console.log(await avatar.getAvatarByNFT(testnft.address, 3));
    console.log(await avatar.getAvatarByNFT(testnft.address, 4));
    console.log(await avatar.getAvatarByNFT(testnft.address, 5));
    console.log(await avatar.getAvatarByNFT(testnft.address, 6));
    console.log(await avatar.getAvatarByNFT(testnft.address, 7));

    console.log(await passMetaDataRender.constructTokenURI(1));

    // 1, 0, -1;
    const moveTo4Tx = await avatar.moveTo([10011000, 2, 1, 1, 0, address0]);
    await moveTo4Tx.wait();

    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(1), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(2), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(3), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(4), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(5), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(6), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(7), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(8), energydecimals));

    const redeemEnergyTx = await governance.redeemAvatarInboxEnergy(1, 0, address0);
    await redeemEnergyTx.wait();

    const multi10Tx = await governance.multicall([
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [2, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [3, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [4, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [5, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [6, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [7, 0, address0]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [8, 0, address0]),
    ]);
    await multi10Tx.wait();

    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(1), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(2), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(3), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(4), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(5), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(6), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(7), energydecimals));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(8), energydecimals));

    console.log(
      "wallet balance",
      ethers.utils.formatUnits(await energy.balanceOf(owner.address), energydecimals)
    );

    const allowanceTx = await energy.approve(
      arsenal.address,
      ethers.BigNumber.from("1000000000000000")
    );
    await allowanceTx.wait();

    console.log(ethers.utils.formatUnits(await arsenal.getCurrentPrice(), energydecimals));
    const buybombtx = await arsenal.buy(2);
    await buybombtx.wait();

    // -2 3 -1
    const bombTx = await avatar.bomb(09981003, 1, 0, address0);
    await bombTx.wait();

    // 0 3 -3
    const bomb1Tx = await avatar.bomb(10001003, 1, 0, address0);
    await bomb1Tx.wait();

    console.log(
      await avatar.getAvatarsByNFTs(
        [
          testnft.address,
          testnft.address,
          testnft.address,
          testnft.address,
          testnft.address,
          testnft.address,
          testnft.address,
          testnft.address,
        ],
        [0, 1, 2, 3, 4, 5, 6, 7]
      )
    );

    console.log(await passMetaDataRender.constructTokenURI(1));
  });
});
