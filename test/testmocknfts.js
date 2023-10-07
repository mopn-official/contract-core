const { ethers } = require("hardhat");
const fs = require("fs");

describe("MOPN", function () {
  let
    mocknftfactroy, mocknftimplementation;

  it("deply Governance", async function () {
    const deployConf = loadConf();

    const MOCKNFTFactory = await ethers.getContractFactory("MOCKNFTFactory");
    mocknftfactroy = await MOCKNFTFactory.deploy();
    await mocknftfactroy.deployed();
    console.log("MOCKNFTFactory:", mocknftfactroy.address, " deployed.");

    const MOCKNFT = await ethers.getContractFactory("MOCKNFT");
    mocknftimplementation = await MOCKNFT.deploy();
    await mocknftimplementation.deployed();
    console.log("MOCKNFT:", mocknftimplementation.address, " deployed.");

    for (let i = 0; i < deployConf.nfts.length; i++) {
      const tx = await mocknftfactroy.createNewMockCollection(
        mocknftimplementation.address,
        i,
        mocknftimplementation.interface.encodeFunctionData('initialize', [
          deployConf.nfts[i].name,
          deployConf.nfts[i].symbol,
          deployConf.nfts[i].baseuri,
          deployConf.nfts[i].uriext
        ])
      );
      const receipt = await tx.wait();

      let collectionAddress;
      for (log of receipt.logs) {
        if (log.address == mocknftfactroy.address) {
          const event = mocknftfactroy.interface.parseLog(log);
          collectionAddress = event.args.collectionAddress;
          console.log(deployConf.nfts[i].name, "deployed to", event.args.collectionAddress);
        }
      }

      if (collectionAddress) {
        const mocknft = await ethers.getContractAt("MOCKNFT", collectionAddress);
        const tx = await mocknft.mint(1000);
        await tx.wait();
      }
    }
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