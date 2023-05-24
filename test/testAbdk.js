const { ethers } = require("hardhat");

describe("AuctionHouse", function () {
  let tileMath, auctionHouse, map;

  it("deploy ", async function () {
    const TileMath = await ethers.getContractFactory("TileMath");
    tileMath = await TileMath.deploy();
    await tileMath.deployed();
    console.log("TileMath", tileMath.address);

    const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
    auctionHouse = await AuctionHouse.deploy(1677184081, 1677184081);
    await auctionHouse.deployed();
    console.log("AuctionHouse", auctionHouse.address);
  });

  it("test ln", async function () {
    console.log(await auctionHouse.testlog(1000000));
  });
});
