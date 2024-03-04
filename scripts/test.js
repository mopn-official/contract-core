const MOPNMath = require("../test/MOPNMath.js");
const { ethers } = require('hardhat');

let mopnFacet
  let mopnDataFacet
  let mopnerc6551accountproxy
  let mopnerc6551accounthelper

let 
    accounts = [],
    tiles = {};

async function test() {
  let diamondAddress
  let contractOwner
  const addresses = []

    const signers = await ethers.getSigners()
    contractOwner = signers[0]

    diamondAddress = '0xa249b58E29eC529cF0374Cb292BdD28F9095e1c6';
    mopnFacet = await ethers.getContractAt('MOPNFacet', diamondAddress)
    mopnDataFacet = await ethers.getContractAt('MOPNDataFacet', diamondAddress)
    mopnerc6551accountproxy = await ethers.getContractAt('MOPNERC6551AccountProxy', await mopnDataFacet.ERC6551AccountProxy())
    mopnerc6551accounthelper = await ethers.getContractAt('MOPNERC6551AccountHelper', await mopnDataFacet.ERC6551AccountHelper()) 
    
    console.log("ERC6551Registry", await mopnDataFacet.ERC6551Registry());
    console.log("mopnerc6551accounthelper", mopnerc6551accounthelper.address);
    console.log("erc6551accountproxy", mopnerc6551accountproxy.address);

    console.log(await mopnDataFacet.getAccountData('0x354F0397BE4476aa3Fb6d5F8497355ddb8d705C4'));
    

  
}

if (require.main === module) {
  test()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}