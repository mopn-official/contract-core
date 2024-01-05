const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const provider = new ethers.JsonRpcProvider(config.networks["mainnet"].url);
  const wallet = new ethers.Wallet(config.networks["mainnet"].accounts[0], provider);

  const vault = await ethers.getContractAt(
    "MOPNCollectionVault",
    "0x21a18221579afb0d6d4de6ef7cc0bf50ceda4ca9",
    wallet
  );

  console.log(await vault.balanceOf("0x4648AFC8392Cefb2Bef07fB9A9fcFD2DE714A3F3"));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
