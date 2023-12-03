const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const collectionsMetadata = Object.values(loadCollectionsMetadata());
  const deployedConf = loadDeployed();

  const implementation = "0xba3e7dae1809a2157f115fe8a29829cb6009223b";

  let mocknftproxy, owner;

  owner = (await ethers.getSigners())[0].address;
  console.log("owner:", owner);

  console.log("deploy start");

  let i = 0;
  for (const collection of collectionsMetadata) {
    if (!deployedConf[collection.mainnetAddress]) {
      console.log("deploy " + collection.name + " index " + i);

      const MOCKNFTProxy = await ethers.getContractFactory("MOCKNFTProxy");
      console.log([
        collection.name,
        collection.symbol,
        owner,
        collection.baseURI,
        collection.extURI,
      ]);
      mocknftproxy = await MOCKNFTProxy.deploy(implementation, owner);
      console.log("https://goerli.etherscan.io/tx/" + mocknftproxy.deploymentTransaction().hash);
      await mocknftproxy.waitForDeployment();
      console.log(collection.name, "deployed to", await mocknftproxy.getAddress());
      deployedConf[collection.mainnetAddress] = {};
      deployedConf[collection.mainnetAddress].mirrorAddress = await mocknftproxy.getAddress();
      i++;
      saveDeployed(deployedConf);
    }

    if (!deployedConf[collection.mainnetAddress].initialize) {
      const mocknft = await ethers.getContractAt(
        "MOCKNFT",
        deployedConf[collection.mainnetAddress].mirrorAddress
      );
      const tx = await mocknft.initialize(
        collection.name,
        collection.symbol,
        owner,
        collection.baseURI,
        collection.extURI
      );
      console.log("https://goerli.etherscan.io/tx/" + tx.hash);
      await tx.wait();
      deployedConf[collection.mainnetAddress].initialize = true;
      saveDeployed(deployedConf);
    }
  }
  console.log("deploy finish");

  console.log("begin verify contracts on goerliscan");
  const keys = Object.keys(deployedConf);
  for (const key of keys) {
    if (!deployedConf[key].verify) {
      verifyData = {
        address: deployedConf[key].mirrorAddress,
        constructorArguments: [implementation, owner],
      };
      await hre.run("verify:verify", verifyData);
      saveDeployed(deployedConf);
    }
  }

  console.log("all contracts verifed");
}

function loadCollectionsMetadata() {
  const deployConf = JSON.parse(
    fs.readFileSync("./src/preprod/testnetmirror/collectionsmetadata.json")
  );

  if (!deployConf) {
    console.log("no deployed config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function loadDeployed() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/testnetmirror/goerlimirror.json"));

  if (!deployConf) {
    console.log("no deployed config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveDeployed(deployConf) {
  fs.writeFile(
    "./src/preprod/testnetmirror/goerlimirror.json",
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
