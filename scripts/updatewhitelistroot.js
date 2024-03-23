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
      "0x93d642229078c797eb4bc9c14da264afbe94ef1f9ce5e9fee89888879a251caf"
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