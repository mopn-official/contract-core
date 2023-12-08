const hre = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const fs = require("fs");

describe("MOPN", function () {
  let mopnauctionHouse;

  it("deploy AuctionHouse", async function () {
    mopnauctionHouse = await hre.ethers.deployContract("MOPNAuctionHouse", [
      "0x3ffe98b5c1c61cc93b684b44aa2373e1263dd4a4",
      1,
    ]);
    console.log("MOPNAuctionHouse", await mopnauctionHouse.getAddress());
  });

  it("test ", async function () {
    console.log(await mopnauctionHouse.testBombPrice());
  });
});
