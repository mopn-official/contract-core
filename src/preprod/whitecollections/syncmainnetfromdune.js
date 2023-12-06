const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const apidata = await axios.get(
    "https://api.dune.com/api/v1/query/3240812/results?api_key=6Gcnsizht126Di5dxEs0970D58i7ZM3h"
  );
  const collectionsdata = apidata.data.result.rows;
  // const collectionsdata = loadDuneCache().result.rows;
  console.log("totalcollections", collectionsdata.length);

  let collections = [[], [], []];
  const collectionstagemapping = {
    "#1": 0,
    "#2": 1,
    "#3": 2,
  };

  for (const collection of collectionsdata) {
    if (collection.stages != "#4") {
      let collectionAddress = collection.collection.match(/href="([^"]*)/)[1];
      collectionAddress = collectionAddress.replace("https://etherscan.io/address/", "");
      collections[collectionstagemapping[collection.stages]].push(collectionAddress);
    }
  }
  console.log(collections);
  saveMainnet(collections);
}

function loadDuneCache() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/whitecollections/example.json"));

  if (!deployConf) {
    console.log("no mainnet nfts");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveMainnet(deployConf) {
  fs.writeFile(
    "./src/preprod/whitecollections/mainnet.json",
    JSON.stringify(deployConf, null, 4),
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
