const { ethers } = require("hardhat");
const fs = require("fs");
const { time, mine } = require("@nomicfoundation/hardhat-network-helpers");
const { ZeroAddress } = require("ethers");

describe("MOPN", function () {
  let mopndata;

  it("deploy MOPN Data", async function () {
    const tileMath = await hre.ethers.deployContract("TileMath");
    await tileMath.waitForDeployment();
    console.log("TileMath", await tileMath.getAddress());

    mopndata = await hre.ethers.deployContract(
      "MOPNData",
      ["0xf2DDf4151ca1719418454150a19Cd86a6faD7705"],
      {
        libraries: {
          TileMath: await tileMath.getAddress(),
        },
      }
    );
    await mopndata.waitForDeployment();
    console.log("MOPNData", await mopndata.getAddress());
  });

  it("test try cache", async function () {
    console.log(await mopndata.calcLandsMT([39], [["0x706a4e2466cea5e3af81fb3b620980fc3f5e0c7d"]]));
  });
});
