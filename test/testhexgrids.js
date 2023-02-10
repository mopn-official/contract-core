const { ethers } = require("hardhat");

describe("HexGridsMath", function () {
  let blockMath;

  it("deploy ", async function () {
    const BlockMath = await ethers.getContractFactory("BlockMath");
    blockMath = await BlockMath.deploy();
    await blockMath.deployed();
    console.log("BlockMath", blockMath.address);
  });

  it("test center blocks", async function () {
    let passId = 17;
    while (true) {
      console.log("passid:", passId, await blockMath.PassCenterBlock(passId));
      passId++;
      if (passId > 10981) {
        break;
      }
    }
  });
});
