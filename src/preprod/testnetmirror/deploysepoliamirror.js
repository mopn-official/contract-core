const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const collections = loadMainnetWhiteCollections();
  const collectionsMetadata = loadCollectionsMetadata();
  const deployedConf = loadDeployed();

  const implementation = "0x2CC76117EE3070aC049dEEF4d704cE4F26a79240";

  let mocknftproxy, owner;

  owner = (await ethers.getSigners())[0].address;
  console.log("owner:", owner);

  console.log("deploy start");

  let i = 0;
  for (const collectionstage of collections) {
    for (const mainnetcollection of collectionstage) {
      const collection = collectionsMetadata[mainnetcollection.collectionAddress];
      if (collection) {
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
          console.log(
            "https://sepolia.etherscan.io/tx/" + mocknftproxy.deploymentTransaction().hash
          );
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
          console.log("https://sepolia.etherscan.io/tx/" + tx.hash);
          await tx.wait();
          deployedConf[collection.mainnetAddress].initialize = true;
          saveDeployed(deployedConf);
        }
      } else {
        console.log(mainnetcollection, "not found");
      }
    }
  }
  console.log("deploy finish");

  console.log("begin verify contracts on sepoliascan");
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
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/testnetmirror/sepoliamirror.json"));

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
    "./src/preprod/testnetmirror/sepoliamirror.json",
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
