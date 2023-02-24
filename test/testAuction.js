const { ethers } = require("hardhat");

describe("AuctionHouse", function () {
  let auctionHouse, governance;

  it("deploy ", async function () {
    const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
    auctionHouse = await AuctionHouse.deploy();
    await auctionHouse.deployed();
    console.log("AuctionHouse", auctionHouse.address);

    const Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy(0, false);
    await governance.deployed();
    console.log("Governance", governance.address);
  });

  it("getLandPrice", async function () {
    console.log(await auctionHouse.getLandPrice(32));
  });

  it("getBombPrice", async function () {
    console.log(await auctionHouse.getBombPrice(32));
  });

  it("currentEPPB", async function () {
    // console.log(await governance.currentEPPB(500));
    // console.log(await governance.currentEPPB(1000));
    // console.log(await governance.currentEPPB(1500));
    // console.log(await governance.currentEPPB(2000));
    // console.log(await governance.currentEPPB(2500));
    // console.log(await governance.currentEPPB(3000));
    // console.log(await governance.currentEPPB(3500));
    // console.log(await governance.currentEPPB(4000));
    // console.log(await governance.currentEPPB(4500));
    // console.log(await governance.currentEPPB(5000));
    // console.log(await governance.currentEPPB(5500));
    // console.log(await governance.currentEPPB(6000));
    // console.log(await governance.currentEPPB(6500));
    // console.log(await governance.currentEPPB(7000));
    // console.log(await governance.currentEPPB(7500));
    // console.log(await governance.currentEPPB(8000));
    console.log(await governance.currentEPPB(499));
    console.log(await governance.currentEPPB(500));
    // for (let i = 8200; i < 8300; i++) {
    //   console.log(i, await governance.currentEPPB(i));
    // }
  });
});
