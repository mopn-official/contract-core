const MOPNMath = require("../test/MOPNMath.js");
const { ethers } = require('hardhat');

let mopnFacet
  let mopnDataFacet
  let mopnerc6551accountproxy
  let mopnerc6551accounthelper

let 
    accounts = [],
    tiles = {};

async function update() {
  let diamondAddress
  let contractOwner
  const addresses = []

    const signers = await ethers.getSigners()
    contractOwner = signers[0]

    mopnland = await ethers.getContractAt('MOPNLand', '0xE027F587b9fdDf22ff1ffFDA800bA14DA8de007a')
    const tx = await mopnland
    .setMainnetClaimer(
      '0xA9f5df38f4111bC87C3F9Db719cBaf9Be872D337'
    );
    await tx.wait();

}

if (require.main === module) {
  update()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}