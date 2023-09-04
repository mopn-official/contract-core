const { ethers } = require("hardhat");
const fs = require("fs");
const { verify } = require("crypto");

async function main() {

  const deployConf = loadConf();

  let contractName, Contract, contract, mocknftminer;

  console.log("deploy start");
  if (deployConf.miner.address != "") {
    mocknftminer = await ethers.getContractAt("MOCKNFTMiner", deployConf.miner.address);
    console.log("MOCKNFTMiner:", mocknftminer.address, " deployed.");
  } else {
    Contract = await ethers.getContractFactory("MOCKNFTMiner");
    mocknftminer = await Contract.deploy();
    console.log("https://goerli.etherscan.io/tx/" + mocknftminer.deployTransaction.hash);
    await mocknftminer.deployed();
    console.log("MOCKNFTMiner:", mocknftminer.address, " deployed.");
    deployConf.miner.address = mocknftminer.address;
    saveConf(deployConf);
  }

  for (let i = 0; i < deployConf.nfts.length; i++) {
    if (deployConf.nfts[i].address != "") {
      console.log(deployConf.nfts[i].name, ":", deployConf.nfts[i].address, " deployed.");
    } else {
      contractName = deployConf.nfts[i].name;
      console.log("deploy " + contractName);
      Contract = await ethers.getContractFactory("MOCKNFT");
      contract = await Contract.deploy(mocknftminer.address, deployConf.nfts[i].name, deployConf.nfts[i].symbol, deployConf.nfts[i].baseuri, deployConf.nfts[i].uriext);
      console.log("https://goerli.etherscan.io/tx/" + contract.deployTransaction.hash);
      await contract.deployed();
      console.log(contractName, ":", contract.address, " deployed.");
      deployConf.nfts[i].address = contract.address;
      saveConf(deployConf);
    }
  }
  console.log("deploy finish");


  console.log("begin verify contracts on goerliscan");
  const verifyData = {
    address: mocknftminer.address
  };
  await hre.run("verify:verify", verifyData);
  for (let i = 0; i < deployConf.nfts.length; i++) {
    contractName = deployConf.nfts[i].name;
    console.log("begin to verify ", contractName, " at ", deployConf.nfts[i].address);
    try {
      const verifyData = {
        address: deployConf.nfts[i].address,
        constructorArguments: [mocknftminer.address, deployConf.nfts[i].name, deployConf.nfts[i].symbol, deployConf.nfts[i].baseuri, deployConf.nfts[i].uriext],
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
  }
  console.log("all contracts verifed");
}

function loadConf() {
  const deployConf = JSON.parse(
    fs.readFileSync("./scripts/mocknfts/nfts.json")
  );

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
