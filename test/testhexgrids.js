const { ethers } = require("hardhat");

describe("HexGridsMath", function () {
  let hexGridsMath, blockMath, intBlockMath;

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

    console.log(hexGridsMath.address);
  });

  it("test", async function () {
    console.log(await hexGridsMath.block_coordinate_bytes([344, 556, -13]));
  });

  it("test center blocks", async function () {
    let passId = 10981;
    while (true) {
      console.log("passid:", passId, await hexGridsMath.PassCenterBlock(passId));
      passId++;
      if (passId > 10981) {
        break;
      }
    }
  });
});
