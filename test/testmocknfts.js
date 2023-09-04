const { ethers } = require("hardhat");
const fs = require("fs");

describe("MOPN", function () {
  let
    mocknftminer;

  it("deply Governance", async function () {
    const deployConf = loadConf();

    Contract = await ethers.getContractFactory("MOCKNFTMiner");
    mocknftminer = await Contract.deploy();
    await mocknftminer.deployed();
    console.log("MOCKNFTMiner:", mocknftminer.address, " deployed.");

    for (let i = 0; i < deployConf.length; i++) {
      contractName = deployConf[i].name;
      console.log("deploy " + contractName);
      Contract = await ethers.getContractFactory("MOCKNFT");
      contract = await Contract.deploy(mocknftminer.address, deployConf[i].name, deployConf[i].symbol, deployConf[i].baseuri, deployConf[i].uriext);
      await contract.deployed();
      console.log(contractName, ":", contract.address, " deployed.");
    }
  });

  it("test mint", async function () {
    const uptx = await mocknftminer.mint();
    await uptx.wait();
  });
});


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