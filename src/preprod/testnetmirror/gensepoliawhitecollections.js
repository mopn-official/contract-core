const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const mainnetcollections = loadMainnetWhiteCollections();
  const deployedConf = loadDeployed();

  let collections = [[], [], []];
  let i = 0;
  for (const collectionstage of mainnetcollections) {
    for (const mainnetcollection of collectionstage) {
      const collection = deployedConf[mainnetcollection.collectionAddress];
      if (collection) {
        collections[i].push({
          collectionAddress: collection.mirrorAddress,
          collectionName: mainnetcollection.collectionName,
        });
      } else {
        console.log(mainnetcollection.collectionAddress, "not found");
      }
    }
    i++;
  }

  saveGoerli(collections);
}

function loadMainnetWhiteCollections() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/whitecollections/mainnet.json"));

  if (!deployConf) {
    console.log("no mainnet nfts");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function loadDeployed() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/testnetmirror/sepoliamirror.json"));

  if (!deployConf) {
    console.log("no deployed config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveGoerli(deployConf) {
  fs.writeFile(
    "./src/preprod/whitecollections/sepolia.json",
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
