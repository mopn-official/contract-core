const { ethers } = require("hardhat");

describe("TileMath", function () {
  let tilekMath;

  it("deploy ", async function () {
    const TileMath = await ethers.getContractFactory("TileMath");
    tilekMath = await TileMath.deploy();
    await tilekMath.deployed();
    console.log("TileMath", tilekMath.address);
  });

  it("test center blocks", async function () {
    let passId = 17;
    while (true) {
      console.log("passid:", passId, await tilekMath.PassCenterTile(passId));
      passId++;
      if (passId > 10981) {
        break;
      }
    }
  });
});
