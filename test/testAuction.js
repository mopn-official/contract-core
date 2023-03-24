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

    const Map = await ethers.getContractFactory("Map", {
      libraries: {
        TileMath: tileMath.address,
      },
    });
    map = await Map.deploy(0);
    await map.deployed();
    console.log("Map", map.address);
  });

  it("getLandPrice", async function () {
    console.log(await auctionHouse.getLandPrice(32));
  });

  it("getBombPrice", async function () {
    console.log(await auctionHouse.getBombPrice(0));
    console.log(await auctionHouse.getBombPrice(300));
    console.log(await auctionHouse.getBombPrice(600));
    console.log(await auctionHouse.getBombPrice(900));
    console.log(await auctionHouse.getBombPrice(1200));
    console.log(await auctionHouse.getBombPrice(1500));
    console.log(await auctionHouse.getBombPrice(1800));
  });

  it("currentMTPPB", async function () {
    console.log(await map.currentMTPPB(0));
    console.log(await map.currentMTPPB(300));
    console.log(await map.currentMTPPB(600));
    console.log(await map.currentMTPPB(900));
    console.log(await map.currentMTPPB(1200));
    console.log(await map.currentMTPPB(1500));
    console.log(await map.currentMTPPB(1800));
  });

  it("currentMTPPB1", async function () {
    console.log(await map.currentMTPPB1(0));
    console.log(await map.currentMTPPB1(300));
    console.log(await map.currentMTPPB1(600));
    console.log(await map.currentMTPPB1(900));
    console.log(await map.currentMTPPB1(1200));
    console.log(await map.currentMTPPB1(1500));
    console.log(await map.currentMTPPB1(1800));
  });
});
