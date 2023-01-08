const { ethers } = require("hardhat");

describe("HexGridsMath", function () {
  let hexGridsMath;

  it("deploy ", async function () {
    const HexGridsMath = await ethers.getContractFactory("HexGridsMath");

    hexGridsMath = await HexGridsMath.deploy();
    await hexGridsMath.deployed();

    console.log(hexGridsMath.address);
  });

  it("test", async function () {
    console.log(await hexGridsMath.block_coordinate_bytes([344, 556, -13]));
  });
});
