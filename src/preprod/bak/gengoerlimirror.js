const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const mainnetnfts = Object.values(loadMainnetNFTs());
  let goerlimirror = {};
  let collecions = {};

  for (const mainnetnft of mainnetnfts) {
    goerlimirror[mainnetnft.mainnetAddress] = {
      mirrorAddress: mainnetnft.collectionAddress,
      initialize: mainnetnft.initialize,
    };
    collecions[mainnetnft.mainnetAddress] = {
      mainnetAddress: mainnetnft.mainnetAddress,
      name: mainnetnft.name,
      symbol: mainnetnft.symbol,
      baseURI: mainnetnft.baseURI,
      extURI: mainnetnft.extURI,
      tokenURIexample: mainnetnft.tokenURIexample,
    };
  }
  saveMainnetNFTs(collecions);
  saveGoerliMirror(goerlimirror);
}

function loadMainnetNFTs() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/metadata/collections.json"));

  if (!deployConf) {
    console.log("no mainnet nfts");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveMainnetNFTs(deployConf) {
  fs.writeFile(
    "./src/preprod/metadata/collections.json",
    JSON.stringify(deployConf, null, 4),
    "utf8",
    function (err) {
      if (err) throw err;
    }
  );
}

function saveGoerliMirror(goerlimirror) {
  fs.writeFile(
    "./src/preprod/metadata/goerlimirror.json",
    JSON.stringify(goerlimirror, null, 4),
    "utf8",
    function (err) {
      if (err) throw err;
    }
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
