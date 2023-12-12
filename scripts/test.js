const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const provider = new ethers.JsonRpcProvider(config.networks["mainnet"].url);
  const wallet = new ethers.Wallet(config.networks["mainnet"].accounts[0], provider);

  const mopndata = await ethers.getContractAt(
    "MOPNData",
    "0x4E271c67DeB30267C74a12b1Cfd25b5782BCf21c",
    wallet
  );

  console.log(await mopndata.calcLandsMT([39], [["0x706a4e2466cea5e3af81fb3b620980fc3f5e0c7d"]]));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
