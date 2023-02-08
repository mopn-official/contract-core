const { ethers } = require("hardhat");

describe("HexGridsMath", function () {
  let blockMath, intBlockMath;

  it("deploy ", async function () {
    const BlockMath = await ethers.getContractFactory("BlockMath");
    blockMath = await BlockMath.deploy();
    await blockMath.deployed();
    console.log("BlockMath", blockMath.address);

    const IntBlockMath = await ethers.getContractFactory("IntBlockMath");
    intBlockMath = await IntBlockMath.deploy();
    await intBlockMath.deployed();
    console.log("IntBlockMath", intBlockMath.address);
  });

  it("test center blocks", async function () {
    let passId = 10981;
    while (true) {
      console.log("passid:", passId, await intBlockMath.PassCenterBlock(passId));
      passId++;
      if (passId > 10981) {
        break;
      }
    }
  });
});
