const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const provider = new ethers.JsonRpcProvider(config.networks["mainnet"].url);
  const wallet = new ethers.Wallet(config.networks["mainnet"].accounts[0], provider);

  const bomb = await ethers.getContractAt(
    "MOPNBomb",
    "0x058Bf43a0b7eEd6Cc7e9A032d418B7B95E9A5371",
    wallet
  );

  console.log(await bomb.uri(1));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
