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

    const HexGridsMath = await ethers.getContractFactory("HexGridsMath", {
      libraries: {
        BlockMath: blockMath.address,
        IntBlockMath: intBlockMath.address,
      },
    });
    hexGridsMath = await HexGridsMath.deploy();
    await hexGridsMath.deployed();
    console.log("HexGridsMath", hexGridsMath.address);

    const Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy(0);
    await governance.deployed();
    console.log("Governance", governance.address);

    const Map = await ethers.getContractFactory("Map", {
      libraries: {
        BlockMath: blockMath.address,
        IntBlockMath: intBlockMath.address,
        HexGridsMath: hexGridsMath.address,
      },
    });
    map = await Map.deploy();
    await map.deployed();
    console.log("Map", map.address);

    const Avatar = await ethers.getContractFactory("Avatar", {
      libraries: {
        BlockMath: blockMath.address,
        HexGridsMath: hexGridsMath.address,
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

    const governancesetLandtx = await governance.updateLandContract(map.address);
    await governancesetLandtx.wait();

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

    const mintTx = await avatar.mintAvatar(
      ["0xaf0Eafef41b90C0E561E711f51151DBbA0ABa72D", 1],
      ["0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530"]
    );
    await mintTx.wait();

    const mintTx1 = await avatar.mintAvatar(
      ["0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 1],
      ["0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18"]
    );
    await mintTx1.wait();

    const mintTx2 = await avatar.mintAvatar(
      ["0xeDf9672409F73E844fAaf01e9d9A6862B13D9020", 2],
      ["0x660483c9423322a71099c52233f089835b378b91a001de56752188209c448f18"]
    );
    await mintTx2.wait();

    // [0, 0, 0, 0, 0, 0, 0]
    const moveToTx = await avatar.moveTo([1, -1, 0], 0, 1, 1);
    await moveToTx.wait();

    // const moveTo1Tx = await avatar.moveTo([0, 2, -2], 0, 2, 1);
    // await moveTo1Tx.wait();

    // const moveTo2Tx = await avatar.moveTo([1, 2, -3], 2, 3, 1);
    // await moveTo2Tx.wait();

    // console.log(await avatar.getAvatarOccupiedBlock(1));
    // console.log(await avatar.getAvatarOccupiedBlock(2));
    // console.log(await avatar.getAvatarOccupiedBlock(3));

    // const moveTo3Tx = await avatar.moveTo([1, -2, 1], 1, 1, 1);
    // await moveTo3Tx.wait();

    // const bombTx = await avatar.bomb([0, 2, -2], 1);
    // await bombTx.wait();

    // console.log(await avatar.getAvatarOccupiedBlock(1));
    // console.log(await avatar.getAvatarOccupiedBlock(2));
    // console.log(await avatar.getAvatarOccupiedBlock(3));

    // console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(1)));
    // console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(2)));
    // console.log(ethers.utils.formatUnits(await governance.getAvatarInboxEnergy(3)));

    const redeemEnergyTx = await governance.redeemAvatarInboxEnergy(1);
    await redeemEnergyTx.wait();

    console.log(ethers.utils.formatUnits(await energy.balanceOf(owner.address)));

    const allowanceTx = await energy.approve(
      arsenal.address,
      ethers.BigNumber.from("5400000000000000000000")
    );
    await allowanceTx.wait();

    console.log(ethers.utils.formatUnits(await arsenal.getCurrentPrice()));
    const buybombtx = await arsenal.buy(1);
    await buybombtx.wait();

    // console.log(await avatar.getAvatarOccupiedBlockInt(1));
  });
});
