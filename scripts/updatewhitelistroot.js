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
      "0xf00b71425f9a6e8c07544235fedd666c1b5ad83b93b96c3d85dbfcd4cc22b13d"
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