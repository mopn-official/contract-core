const { ethers } = require("hardhat");

describe("MOPN", function () {
  let hexGridsMath, blockMath, avatar, map;

  it("deploy ", async function () {
    const BlockMath = await ethers.getContractFactory("BlockMath");

    blockMath = await BlockMath.deploy();
    await blockMath.deployed();

    console.log("BlockMath", blockMath.address);

    const HexGridsMath = await ethers.getContractFactory("HexGridsMath", {
      libraries: {
        BlockMath: blockMath.address,
      },
    });

    hexGridsMath = await HexGridsMath.deploy();
    await hexGridsMath.deployed();

    console.log("HexGridsMath", hexGridsMath.address);

    const Map = await ethers.getContractFactory("Map", {
      libraries: {
        BlockMath: blockMath.address,
        HexGridsMath: hexGridsMath.address,
      },
    });
    map = await Map.deploy();
    await map.deployed();

    console.log("Map", map.address);

    const Avatar = await ethers.getContractFactory("Avatar", {
      libraries: {
        BlockMath: blockMath.address,
        // HexGridsMath: hexGridsMath.address,
      },
    });
    avatar = await Avatar.deploy("MOPN Avatar", "MOPNA", map.address);
    await avatar.deployed();

    console.log("Avatar", avatar.address);

    const mapsetavatarcontracttx = await map.setAvatarContract(avatar.address);
    await mapsetavatarcontracttx.wait();
  });

  it("test mint nft", async function () {
    const jumpInTx = await avatar.jumpIn([
      [1, 0, -1],
      0,
      0,
      ["0x5FbDB2315678afecb367f032d93F642f64180aa3", 0],
    ]);
    await jumpInTx.wait();

    const jumpInTx1 = await avatar.jumpIn([
      [0, 1, -1],
      1,
      0,
      ["0x5FbDB2315678afecb367f032d93F642f64180aa3", 1],
    ]);
    await jumpInTx1.wait();

    const moveToTx = await avatar.moveTo([
      [1, -1, 0],
      2,
      1,
      ["0x0000000000000000000000000000000000000000", 0],
    ]);
    await moveToTx.wait();

    console.log(await avatar.getAvatarOccupiedBlock(1));

    const blocks = await avatar.getAvatarSphereBlocks(1);
    console.log(blocks);

    console.log(await map.getBlocksAvatars(blocks));
  });
});
