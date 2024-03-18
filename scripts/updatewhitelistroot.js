const MOPNMath = require("../test/MOPNMath.js");
const { ethers } = require('hardhat');

let mopnFacet;
  let mopnGovernanceFacet;

async function move() {
  let diamondAddress;
  

    diamondAddress = '0x038828FA4bFaB1275397ABBAbf54456e76C34083';
    mopnFacet = await ethers.getContractAt('MOPNFacet', diamondAddress)
    mopnGovernanceFacet = await ethers.getContractAt('MOPNGovernanceFacet', diamondAddress)

    const tx = await mopnGovernanceFacet
    .whiteListRootUpdate(
      "0x165478ba58e167a7fdaec683a9aa48a637b3ed60eb2b67a8b9ee21cc5a0d107b"
    );
  await tx.wait();
}

if (require.main === module) {
  move()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}