const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const deployConf = loadConf();

  let contractName, Contract, contract, mocknftfactroy, mocknftimplementation, mocknftproxy;

  console.log("deploy start");
  if (deployConf.factory.address != "") {
    mocknftfactroy = await ethers.getContractAt("MOCKNFTFactory", deployConf.factory.address);
    console.log("MOCKNFTFactory:", mocknftfactroy.address, " deployed.");
  } else {
    const MOCKNFTFactory = await ethers.getContractFactory("MOCKNFTFactory");
    mocknftfactroy = await MOCKNFTFactory.deploy();
    console.log("https://goerli.etherscan.io/tx/" + mocknftfactroy.deployTransaction.hash);
    await mocknftfactroy.deployed();
    console.log("MOCKNFTFactory:", mocknftfactroy.address, " deployed.");
    deployConf.factory.address = mocknftfactroy.address;
    saveConf(deployConf);
  }

  if (deployConf.implementation.address != "") {
    mocknftimplementation = await ethers.getContractAt(
      "MOCKNFT",
      deployConf.implementation.address
    );
    console.log("MOCKNFT:", mocknftimplementation.address, " deployed.");
  } else {
    const MOCKNFT = await ethers.getContractFactory("MOCKNFT");
    mocknftimplementation = await MOCKNFT.deploy();
    console.log("https://goerli.etherscan.io/tx/" + mocknftimplementation.deployTransaction.hash);
    await mocknftimplementation.deployed();
    console.log("MOCKNFT:", mocknftimplementation.address, " deployed.");
    deployConf.implementation.address = mocknftimplementation.address;
    saveConf(deployConf);
  }

  if (deployConf.proxy.address != "") {
    mocknftproxy = await ethers.getContractAt("MOCKNFTProxy", deployConf.proxy.address);
    console.log("MOCKNFTProxy:", mocknftproxy.address, " deployed.");
  } else {
    const MOCKNFTProxy = await ethers.getContractFactory("MOCKNFTProxy");
    mocknftproxy = await MOCKNFTProxy.deploy(mocknftimplementation.address);
    console.log("https://goerli.etherscan.io/tx/" + mocknftproxy.deployTransaction.hash);
    await mocknftproxy.deployed();
    console.log("MOCKNFTProxy:", mocknftproxy.address, " deployed.");
    deployConf.proxy.address = mocknftproxy.address;
    saveConf(deployConf);
  }

  let i = 0;
  for (const key in deployConf.collections) {
    console.log("deploy " + deployConf.collections[key].name + " index " + i);

    const tx = await mocknftfactroy.createNewMockCollection(
      mocknftproxy.address,
      i,
      mocknftimplementation.interface.encodeFunctionData("initialize", [
        deployConf.collections[key].name,
        deployConf.collections[key].symbol,
        deployConf.collections[key].baseURI,
        deployConf.collections[key].extURI,
      ])
    );
    console.log("https://goerli.etherscan.io/tx/" + tx.hash);
    const receipt = await tx.wait();

    let deployedAddress;
    for (log of receipt.logs) {
      if (log.address == mocknftfactroy.address) {
        const event = mocknftfactroy.interface.parseLog(log);
        deployedAddress = event.args.collectionAddress;
        console.log(deployConf.collections[key].name, "deployed to", deployedAddress);
      }
    }
    deployConf.collections[key].collectionAddress = deployedAddress;

    i++;
    saveConf(deployConf);
  }
  console.log("deploy finish");

  console.log("begin verify contracts on goerliscan");
  try {
    let verifyData = {
      address: mocknftfactroy.address,
    };
    await hre.run("verify:verify", verifyData);
    verifyData = {
      address: mocknftproxy.address,
      constructorArguments: [mocknftimplementation.address],
    };
    await hre.run("verify:verify", verifyData);
    verifyData = {
      address: mocknftimplementation.address,
    };
    await hre.run("verify:verify", verifyData);
  } catch (e) {
    if (
      e.toString() == "Reason: Already Verified" ||
      e.toString() == "NomicLabsHardhatPluginError: Contract source code already verified"
    ) {
      console.log(deployConf.nfts[i].name + " already verified");
    } else {
      console.log("verify failed " + e.toString());
    }
  }

  console.log("all contracts verifed");
}

function loadConf() {
  const deployConf = JSON.parse(fs.readFileSync("./scripts/mocknfts/nfts.json"));

  if (!deployConf) {
    console.log("no deploy config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveConf(deployConf) {
  fs.writeFile(
    "./scripts/mocknfts/nfts.json",
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
