/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

const deployed = {
  'ERC6551Registry': '0x0ab55a515007c82a60ecD6EF6F149Fa2A6891094',
  'MOPNERC6551AccountHelper': '0x250Cf1c8f112a7872f17C5e8BB5c9E8F0aE55F11',
  'MOPNERC6551Account': '0xd6E3AAc6a94259ae9553c94DA78fe601e482815E',
  'MOPNERC6551AccountProxy': '0xAb464058d6305233cc71E9c446810B3B997D4E36',
  'DiamondCutFacet': '0x90205dC32d976C6c36e5c5578b493dea31599a48',
  'Diamond':'0xf6966EC7D840Cd9861398C97516de0A3Ed69df5d',
  'MOPNBomb': '0x10E6D870D2AF151E69d709252080a930C3ec75FC',
  'MOPNToken': '0xAC73c2acfD96908242d408200e5725F29407f2E0',
  'MOPNCollectionVault': '0x3f7E337337257aBfA3BEdbEe15FEaCfda4717E18',
  'MOPNLand': '0x8D40BE115d9085961ee24735Da770d2F64F159Cf',
  'DiamondInit': '0xE527e71ebf1a70edD37cD8D034b40B19920De9AF',
  'DiamondLoupeFacet': '0x780b36471768a0f918f5EA3991cEcB8868c7856a',
  'OwnershipFacet': '0x941Ba91DF46F103C8f60Ee53C866C175529b7d3c',
  'MOPNFacet': '0x47c9F5271C658669BcDC4aa612999545d7314F8F',
  'MOPNAuctionHouseFacet': '0xDeFae17B347Cf556A977A87Abb86Ae1da83E637c',
  'MOPNGovernanceFacet': '0xFA6Ecf5c83b0B86c4A177CA73E497fB138b1631f',
  'MOPNSettlementFacet': '0x1B97c77E0De813E816282240ba224E49B51a89c1',
  'MOPNDataFacet': '0x6400Be6500538EfD2eEbEfDC69dC8538509C2df9'
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
    console.log(`${name} deployed: ${contract.address}`);
  }
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

  const diamond = await deployContract('Diamond', [
    contractOwner.address,
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
    1,
    200000000000000,
    1001,
    contractOwner.address,
    diamond.address,
    diamond.address
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
    'MOPNSettlementFacet',
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
