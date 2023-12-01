const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const deployConf = loadConf();

  let mocknftimplementation, mocknftproxy, owner;

  owner = (await ethers.getSigners())[0].address;
  console.log("owner:", owner);

  console.log("deploy start");

  if (deployConf.implementation.address != "") {
    mocknftimplementation = await ethers.getContractAt(
      "MOCKNFT",
      deployConf.implementation.address
    );
    console.log("MOCKNFT:", await mocknftimplementation.getAddress(), " deployed.");
  } else {
    const MOCKNFT = await ethers.getContractFactory("MOCKNFT");
    mocknftimplementation = await MOCKNFT.deploy();
    console.log(
      "https://goerli.etherscan.io/tx/" + mocknftimplementation.deploymentTransaction().hash
    );
    await mocknftimplementation.waitForDeployment();
    console.log("MOCKNFT:", await mocknftimplementation.getAddress(), " deployed.");
    deployConf.implementation.address = await mocknftimplementation.getAddress();
    saveConf(deployConf);
  }

  let i = 0;
  for (const key in deployConf.collections) {
    const colletion = deployConf.collections[key];
    if (colletion.collectionAddress == "") {
      console.log("deploy " + colletion.name + " index " + i);

      const MOCKNFTProxy = await ethers.getContractFactory("MOCKNFTProxy");
      console.log([colletion.name, colletion.symbol, owner, colletion.baseURI, colletion.extURI]);
      mocknftproxy = await MOCKNFTProxy.deploy(await mocknftimplementation.getAddress(), owner);
      console.log("https://goerli.etherscan.io/tx/" + mocknftproxy.deploymentTransaction().hash);
      await mocknftproxy.waitForDeployment();
      console.log(colletion.name, "deployed to", await mocknftproxy.getAddress());
      deployConf.collections[key].collectionAddress = await mocknftproxy.getAddress();
      i++;
      saveConf(deployConf);
    }

    if (!colletion.initialize) {
      const mocknft = await ethers.getContractAt(
        "MOCKNFT",
        deployConf.collections[key].collectionAddress
      );
      const tx = await mocknft.initialize(
        colletion.name,
        colletion.symbol,
        owner,
        colletion.baseURI,
        colletion.extURI
      );
      console.log("https://goerli.etherscan.io/tx/" + tx.hash);
      await tx.wait();
      deployConf.collections[key].initialize = true;
      saveConf(deployConf);
    }
  }
  console.log("deploy finish");

  console.log("begin verify contracts on goerliscan");
  try {
    verifyData = {
      address: await mocknftimplementation.getAddress(),
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

  for (const key in deployConf.collections) {
    const colletion = deployConf.collections[key];
    verifyData = {
      address: colletion.collectionAddress,
      constructorArguments: [await mocknftimplementation.getAddress(), owner],
    };
    await hre.run("verify:verify", verifyData);
  }

  console.log("all contracts verifed");
}

function loadConf() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/mocknfts/goerlimirrornfts.json"));

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
    "./src/preprod/mocknfts/goerlimirrornfts.json",
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
