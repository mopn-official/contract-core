const { ethers } = require("hardhat");

describe("MOPN", function () {
  let hexGridsMath, intBlockMath, blockMath, governance, arsenal, avatar, map, bomb, energy;

  it("deploy ", async function () {
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
      "0xb6ed762e8f2d2616d1161b1379878a2c05a049a760d707deff79de4bccd39730"
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

    const mintTx = await avatar.mintAvatar("0xaf0Eafef41b90C0E561E711f51151DBbA0ABa72D", 1, [
      "0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530",
    ]);
    await mintTx.wait();

    const mintTx1 = await avatar.mintAvatar("0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 1, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    ]);
    await mintTx1.wait();

    const mintTx2 = await avatar.mintAvatar("0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 2, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    ]);
    await mintTx2.wait();

    const mintTx3 = await avatar.mintAvatar("0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 3, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    ]);
    await mintTx3.wait();

    const mintTx4 = await avatar.mintAvatar("0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 4, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    ]);
    await mintTx4.wait();

    const mintTx5 = await avatar.mintAvatar("0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 5, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    ]);
    await mintTx5.wait();

    const mintTx6 = await avatar.mintAvatar("0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 6, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    ]);
    await mintTx6.wait();

    const mintTx7 = await avatar.mintAvatar("0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 7, [
      "0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18",
    ]);
    await mintTx7.wait();

    // 1 -1 0
    const jumpInTx = await avatar.jumpIn(100109991000, 0, 1, 1);
    await jumpInTx.wait();

    // 0 3 -3
    const jumpIn3Tx = await avatar.jumpIn(100010030997, 0, 2, 1);
    await jumpIn3Tx.wait();

    // 0 2 -2
    const jumpIn1Tx = await avatar.jumpIn(100010020998, 2, 3, 1);
    await jumpIn1Tx.wait();

    // 1 2 -3
    const jumpIn2Tx = await avatar.jumpIn(100110020997, 2, 4, 1);
    await jumpIn2Tx.wait();

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

    // 1, -2, 1;
    const moveTo4Tx = await avatar.moveTo(100109981001, 0, 1, 1);
    await moveTo4Tx.wait();

    // -2 3 -1
    const bombTx = await avatar.bomb(100010030997, 1);
    await bombTx.wait();

    console.log(await avatar.getAvatarOccupiedBlock(1));
    console.log(await avatar.getAvatarOccupiedBlock(2));
    console.log(await avatar.getAvatarOccupiedBlock(3));
    console.log(await avatar.getAvatarOccupiedBlock(4));
    console.log(await avatar.getAvatarOccupiedBlock(5));
    console.log(await avatar.getAvatarOccupiedBlock(6));
    console.log(await avatar.getAvatarOccupiedBlock(7));
    console.log(await avatar.getAvatarOccupiedBlock(8));

    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(1)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(2)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(3)));
    console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(4)));

    const redeemEnergyTx = await governance.redeemAvatarInboxEnergy(1);
    await redeemEnergyTx.wait();

    const redeemEnergy1Tx = await governance.redeemAvatarInboxEnergy(2);
    await redeemEnergy1Tx.wait();

    console.log(ethers.utils.formatUnits(await energy.balanceOf(owner.address)));

    const allowanceTx = await energy.approve(
      arsenal.address,
      ethers.BigNumber.from("10000000000000000000000")
    );
    await allowanceTx.wait();

    console.log(ethers.utils.formatUnits(await arsenal.getCurrentPrice()));
    const buybombtx = await arsenal.buy(1);
    await buybombtx.wait();

    // console.log(await avatar.getAvatarOccupiedBlockInt(1));
  });
});
