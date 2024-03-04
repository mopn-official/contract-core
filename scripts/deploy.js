/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

const deployed = {
  "ERC6551Registry": "0x7E3BAf42Ec4dae4FC55C09B4AE63A3A210252Fc8",
  "MOPNERC6551AccountHelper": "0xa7180bC0BCcDEaa2cBd9384C0216f8D8Acb8fC55",
  "MOPNERC6551Account": "0xE12192F31E819fF7dA722349C188B8ae0F0594E2",
  "MOPNERC6551AccountProxy": "0x344E053688ED3a0c061E610172705380AC32Ce7A",
  "DiamondCutFacet": "0xba7Bf786C4fBCC35EE6Dc427895ad0DeaD6EE1Cf",
  "MOPNDiamond": "0xa249b58E29eC529cF0374Cb292BdD28F9095e1c6",
  "MOPNBomb": "0xE1624cb293611233a1746Ee01442DD1eaA095b5F",
  "MOPNToken": "0x694bE0de186CB5C9e08246d4b4a956387e258238",
  "MOPNCollectionVault": "0xeB28B7cA92c100E12ef76e582Fd84c2b68E45671",
  "MOPNLand": "0xE027F587b9fdDf22ff1ffFDA800bA14DA8de007a",
  "MOPNGasVault": "0x9E13161295d3bE7236bb3f476881A64f6Be47C57",
  "DiamondInit": "0x3286F7dA84493014C4bCC8Dfea59dce37B32B6bb",
  "DiamondLoupeFacet": "0x797059Baa33DcFCD613397d6EfD5D3af074B3c3B",
  "OwnershipFacet": "0xdd5c4eE5d59B87b713bD93E6C54C14eb0CDF67D6",
  "MOPNFacet": "0xC9AaF151E2229D97963e1ea29B3Ff5431d81A6c9",
  "MOPNAuctionHouseFacet": "0xA4281Ef90283Cb8DeD6C2b5c0aC13Bf77013A022",
  "MOPNGovernanceFacet": "0xB0c7F4BfC701040A350eCDe91155Be1aa4DDbbDd",
  "MOPNDataFacet": "0xb57889BEF0AE7bbCDC8d05A587601FA6ae8E1544"
};

async function deployContract(name, params) {
  let contract;
  if(deployed[name]) {
    contract = await ethers.getContractAt(name, deployed[name]);
  } else {
    const Contract = await ethers.getContractFactory(name);
    if(params) {
      contract = await Contract.deploy(...params);
    } else {
      contract = await Contract.deploy();
    }
    await contract.deployed();
  }
  console.log(`${name} deployed: ${contract.address}`);
  return contract;
}

async function deployDiamond () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // deploy ERC6551Registry
  const erc6551Registry = await deployContract('ERC6551Registry');

  const mopnerc6551AccountHelper = await deployContract('MOPNERC6551AccountHelper', [
    erc6551Registry.address
  ]);

  const mopnerc6551Account = await deployContract('MOPNERC6551Account', [
    mopnerc6551AccountHelper.address
  ]);

  const mopnerc6551AccountProxy = await deployContract('MOPNERC6551AccountProxy', [
    mopnerc6551Account.address
  ]);

  const diamondCutFacet = await deployContract('DiamondCutFacet');

  const diamond = await deployContract('MOPNDiamond', [
    contractOwner.address,
    diamondCutFacet.address
  ]);
  
  const mopnbomb = await deployContract('MOPNBomb', [
    diamond.address
  ]);

  const mopntoken = await deployContract('MOPNToken', [
    diamond.address
  ]);

  const mopncollectionvault = await deployContract('MOPNCollectionVault', [
    diamond.address
  ]);
  
  const mopnland = await deployContract('MOPNLand', [
    '0x4200000000000000000000000000000000000007',
    diamond.address,
    contractOwner.address,
  ]);

  const mopngasvault = await deployContract('MOPNGasVault', [
    contractOwner.address,
  ]);

  const diamondInit = await deployContract('DiamondInit');

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet',
    'MOPNFacet',
    'MOPNAuctionHouseFacet',
    'MOPNGovernanceFacet',
    'MOPNDataFacet',
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const facet = await deployContract(FacetName)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  // upgrade diamond with facets
  console.log('')
  console.log('Diamond Cut:', cut)
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData('init')
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')

  console.log('')
  console.log('update erc6551 contract')
  const mopn = await ethers.getContractAt('MOPNGovernanceFacet', diamond.address)
  tx = await mopn.updateERC6551Contract(erc6551Registry.address, mopnerc6551AccountProxy.address, mopnerc6551AccountHelper.address)
  console.log('update erc6551 contract tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`update erc6551 contract failed: ${tx.hash}`)
  }
  console.log('Completed update erc6551 contract')

  console.log('')
  console.log('update mopn contract')
  tx = await mopn.updateMOPNContracts(mopnbomb.address, mopntoken.address, mopnland.address, mopncollectionvault.address)
  console.log('update mopn contract tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`update mopn contract failed: ${tx.hash}`)
  }
  console.log('Completed update mopn contract')
  return diamond.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
