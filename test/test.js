const { ethers } = require("hardhat");

describe("MOPN", function () {
  let testnft, intBlockMath, blockMath, governance, arsenal, avatar, map, bomb, energy;

  it("deploy ", async function () {
    const TESTNFT = await ethers.getContractFactory("TESTNFT");
    testnft = await TESTNFT.deploy();
    await testnft.deployed();
    console.log("TESTNFT ", testnft.address);

    const BlockMath = await ethers.getContractFactory("BlockMath");
    blockMath = await BlockMath.deploy();
    await blockMath.deployed();
    console.log("BlockMath", blockMath.address);

    const IntBlockMath = await ethers.getContractFactory("IntBlockMath");
    intBlockMath = await IntBlockMath.deploy();
    await intBlockMath.deployed();
    console.log("IntBlockMath", intBlockMath.address);

    const Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy(0);
    await governance.deployed();
    console.log("Governance", governance.address);

    const Map = await ethers.getContractFactory("Map", {
      libraries: {
        // BlockMath: blockMath.address,
        IntBlockMath: intBlockMath.address,
      },
    });
    map = await Map.deploy();
    await map.deployed();
    console.log("Map", map.address);

    const Avatar = await ethers.getContractFactory("Avatar", {
      libraries: {
        // BlockMath: blockMath.address,
        IntBlockMath: intBlockMath.address,
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

    const Arsenal = await ethers.getContractFactory("Arsenal");
    arsenal = await Arsenal.deploy();
    await arsenal.deployed();
    console.log("Arsenal", arsenal.address);

    const energytransownertx = await energy.transferOwnership(governance.address);
    await energytransownertx.wait();

    const governancesetroottx = await governance.updateWhiteList(
      "0x8a746c884b5d358e2337e88b5da1afe745ffe4a3a5a378819ec41d0979c9931b"
    );
    await governancesetroottx.wait();

    const governancesetarsenaltx = await governance.updateArsenalContract(arsenal.address);
    await governancesetarsenaltx.wait();

    const governancesetavatartx = await governance.updateAvatarContract(avatar.address);
    await governancesetavatartx.wait();

    const governancesetbombtx = await governance.updateBombContract(bomb.address);
    await governancesetbombtx.wait();

    const governancesetmaptx = await governance.updateMapContract(map.address);
    await governancesetmaptx.wait();

    const governancesetpasstx = await governance.updatePassContract(map.address);
    await governancesetpasstx.wait();

    const governancesetenergytx = await governance.updateEnergyContract(energy.address);
    await governancesetenergytx.wait();

    const mapsetgovernancecontracttx = await map.setGovernanceContract(governance.address);
    await mapsetgovernancecontracttx.wait();

    const avatarsetgovernancecontracttx = await avatar.setGovernanceContract(governance.address);
    await avatarsetgovernancecontracttx.wait();

    const arsenalsetgovernancecontracttx = await arsenal.setGovernanceContract(governance.address);
    await arsenalsetgovernancecontracttx.wait();
  });

  it("test mint nft", async function () {
    const [owner] = await ethers.getSigners();
    const mintbombtx = await bomb.mint(owner.address, 1, 1);
    await mintbombtx.wait();

    const transownertx = await bomb.transferOwnership(governance.address);
    await transownertx.wait();

    let mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const multiTx = await avatar.multicall([
      avatar.interface.encodeFunctionData("mintAvatar", [
        testnft.address,
        0,
        [
          "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
          "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
        ],
      ]),
      avatar.interface.encodeFunctionData("jumpIn", [100010001000, 0, 1, 1]),
    ]);
    await multiTx.wait();

    // const mintTx = await avatar.mintAvatar(testnft.address, 0, [
    //   "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    //   "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    // ]);
    // await mintTx.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx1 = await avatar.mintAvatar(testnft.address, 1, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ]);
    await mintTx1.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx2 = await avatar.mintAvatar(testnft.address, 2, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ]);
    await mintTx2.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx3 = await avatar.mintAvatar(testnft.address, 3, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ]);
    await mintTx3.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx4 = await avatar.mintAvatar(testnft.address, 4, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ]);
    await mintTx4.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx5 = await avatar.mintAvatar(testnft.address, 5, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ]);
    await mintTx5.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx6 = await avatar.mintAvatar(testnft.address, 6, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ]);
    await mintTx6.wait();

    mintnfttx = await testnft.safeMint(owner.address);
    await mintnfttx.wait();

    const mintTx7 = await avatar.mintAvatar(testnft.address, 7, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ]);
    await mintTx7.wait();

    // 0 0 0
    // const jumpInTx = await avatar.jumpIn(100010001000, 0, 1, 1);
    // await jumpInTx.wait();

    // 0 3 -3
    const jumpIn1Tx = await avatar.jumpIn(100010030997, 1, 2, 1);
    await jumpIn1Tx.wait();

    // 0 2 -2
    const jumpIn2Tx = await avatar.jumpIn(100010020998, 2, 3, 1);
    await jumpIn2Tx.wait();

    // 1 2 -3
    const jumpIn3Tx = await avatar.jumpIn(100110020997, 2, 4, 1);
    await jumpIn3Tx.wait();

    // -1 3 -2
    const jumpIn4Tx = await avatar.jumpIn(099910030998, 2, 5, 1);
    await jumpIn4Tx.wait();

    // -1 4 -3
    const jumpIn5Tx = await avatar.jumpIn(099910040997, 2, 6, 1);
    await jumpIn5Tx.wait();

    // 0 4 -4
    const jumpIn6Tx = await avatar.jumpIn(100010040996, 2, 7, 1);
    await jumpIn6Tx.wait();

    // 1 3 -4
    const jumpIn7Tx = await avatar.jumpIn(100110030996, 2, 8, 1);
    await jumpIn7Tx.wait();

    console.log(await avatar.getAvatarOccupiedBlock(1));
    console.log(await avatar.getAvatarOccupiedBlock(2));
    console.log(await avatar.getAvatarOccupiedBlock(3));
    console.log(await avatar.getAvatarOccupiedBlock(4));
    console.log(await avatar.getAvatarOccupiedBlock(5));
    console.log(await avatar.getAvatarOccupiedBlock(6));
    console.log(await avatar.getAvatarOccupiedBlock(7));
    console.log(await avatar.getAvatarOccupiedBlock(8));

    // 1, 0, -1;
    const moveTo4Tx = await avatar.moveTo(100110000999, 2, 1, 1);
    await moveTo4Tx.wait();

    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(1)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(2)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(3)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(4)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(5)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(6)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(7)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(8)));

    const redeemEnergyTx = await governance.redeemAvatarInboxEnergy(1);
    await redeemEnergyTx.wait();

    const multi1Tx = await governance.multicall([
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [2]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [3]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [4]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [5]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [6]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [7]),
      governance.interface.encodeFunctionData("redeemAvatarInboxEnergy", [8]),
    ]);
    await multi1Tx.wait();

    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(1)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(2)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(3)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(4)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(5)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(6)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(7)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(8)));

    console.log("wallet balance", ethers.utils.formatUnits(await energy.balanceOf(owner.address)));

    const allowanceTx = await energy.approve(
      arsenal.address,
      ethers.BigNumber.from("10000000000000000000000000")
    );
    await allowanceTx.wait();

    console.log(ethers.utils.formatUnits(await arsenal.getCurrentPrice()));
    const buybombtx = await arsenal.buy(2);
    await buybombtx.wait();

    // -2 3 -1
    const bombTx = await avatar.bomb(099810030999, 1);
    await bombTx.wait();

    // 0 3 -3
    const bomb1Tx = await avatar.bomb(100010030997, 1);
    await bomb1Tx.wait();

    console.log(await avatar.getAvatarOccupiedBlock(1));
    console.log(await avatar.getAvatarOccupiedBlock(2));
    console.log(await avatar.getAvatarOccupiedBlock(3));
    console.log(await avatar.getAvatarOccupiedBlock(4));
    console.log(await avatar.getAvatarOccupiedBlock(5));
    console.log(await avatar.getAvatarOccupiedBlock(6));
    console.log(await avatar.getAvatarOccupiedBlock(7));
    console.log(await avatar.getAvatarOccupiedBlock(8));

    // console.log(await avatar.getAvatarOccupiedBlockInt(1));
  });
});
