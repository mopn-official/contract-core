const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const deployConf = loadConf();
  const bufferpoints = loadPoints();
  const addresses = [];
  const points = [];
  for (let i = 0; i < bufferpoints.length; i++) {
    addresses.push(bufferpoints[i].address);
    points.push(parseInt(bufferpoints[i].top_offer_price.toFixed(2) * 100));
  }

  const mopn = await ethers.getContractAt("MOPN", deployConf["MOPN"].address);
  const tx = await mopn.batchSetCollectionAdditionalMOPNPoints(addresses, points);
  tx.wait();
}

function loadConf() {
  const deployConf = JSON.parse(
    fs.readFileSync("./scripts/deployconf/" + hre.network.name + ".json")
  );

  if (!deployConf) {
    console.log("no deploy config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function loadPoints() {
  const points = JSON.parse(
    fs.readFileSync("./scripts/additionalpoints/" + hre.network.name + ".json")
  );

  if (!points) {
    console.log("no additional points config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return points;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});