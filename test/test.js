const { ethers } = require("hardhat");

describe("MOPN", function () {
  let hexGridsMath, intBlockMath, blockMath, governance, avatar, map;

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
    governance = await Governance.deploy();
    await governance.deployed();
    console.log("Governance", governance.address);

    const Map = await ethers.getContractFactory("Map", {
      libraries: {
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
    avatar = await Avatar.deploy(governance.address, map.address);
    await avatar.deployed();
    console.log("Avatar", avatar.address);

    const mapsetavatarcontracttx = await map.setAvatarContract(avatar.address);
    await mapsetavatarcontracttx.wait();

    const mapsetgovernancecontracttx = await map.setGovernanceContract(governance.address);
    await mapsetgovernancecontracttx.wait();

    const governancesetroottx = await governance.updateWhiteList(
      "0xb6ed762e8f2d2616d1161b1379878a2c05a049a760d707deff79de4bccd39730"
    );
    await governancesetroottx.wait();

    const governancesetavatartx = await governance.updateAvatarContract(avatar.address);
    await governancesetavatartx.wait();

    const governancesetpasstx = await governance.updatePassContract(map.address);
    await governancesetpasstx.wait();
  });

  it("test mint nft", async function () {
    const mintTx = await avatar.mintAvatar(
      ["0xaf0Eafef41b90C0E561E711f51151DBbA0ABa72D", 1],
      ["0x9256bc91b3d0811380fcab6b348b4ae8d6911b36f2e791c21a3408dbed596530"]
    );
    await mintTx.wait();
    const addATTTx = await avatar.addATT(1, 1);
    await addATTTx.wait();

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
    const moveToTx = await avatar.moveTo([1, -1, 0], 0, 1, false);
    await moveToTx.wait();

    const moveTo1Tx = await avatar.moveTo([0, 2, -2], 0, 2, false);
    await moveTo1Tx.wait();

    const moveTo2Tx = await avatar.moveTo([2, 1, -3], 2, 3, false);
    await moveTo2Tx.wait();

    console.log(await avatar.getAvatarOccupiedBlock(1));
    console.log(await avatar.getAvatarOccupiedBlock(2));
    console.log(await avatar.getAvatarOccupiedBlock(3));

    const moveTo3Tx = await avatar.moveTo([-1, 1, 0], 1, 1, true);
    await moveTo3Tx.wait();

    const avatarblock = await avatar.getAvatarOccupiedBlock(1);
    console.log(avatarblock);

    console.log(await avatar.getAvatarOccupiedBlock(2));
    console.log(await avatar.getAvatarOccupiedBlock(3));

    // console.log(await avatar.getAvatarOccupiedBlockInt(1));
  });
});
