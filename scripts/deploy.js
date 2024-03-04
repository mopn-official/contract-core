/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

const deployed = {
    // "ERC6551Registry": "0xdFA4Aa5E394AC48b64ef3D4D80F05aA6ee8456d4",
    // "MOPNERC6551AccountHelper": "0x038828FA4bFaB1275397ABBAbf54456e76C34083",
    // "MOPNERC6551Account": "0x45231c9668289A0C7C434660146eCF48Ef872F4c",
    // "MOPNERC6551AccountProxy": "0xD6e06BBcffdf88aa40D1116Afa42EF1457B0029E",
    // "DiamondCutFacet": "0x3817Ee5BfA85d1f895136918B9D77E4304C7D642",
    // "MOPNDiamond": "0xC99764F086BC5B4Cd140E4723414335738916706",
    // "MOPNBomb": "0xbc25d37Cfea02E78DeD904c02081AA0B524d26F2",
    // "MOPNToken": "0xb12c0b1d96Dc3F4FbD72FE80ace1433c5C500dA0",
    // "MOPNCollectionVault": "0xef92ca528c8B98707704c69619E3c9537FcbBB97",
    // "MOPNLand": "0x0aa51F0109341858B2652Dd616FdFd488e304152",
    // "DiamondInit": "0x447B7C4Bd81b9BaD499748D94eA3B826a4cbA0b2",
    // "DiamondLoupeFacet": "0x5634C5E6aBA379933389B5bd1f4B40273DFAc9E5",
    // "OwnershipFacet": "0x68cA187194073A7949DC9f0160d9e09839A35520",
    // "MOPNFacet": "0xc5496d128cB6f6229f8f2Aebc3cD9D1900750055",
    // "MOPNAuctionHouseFacet": "0x7B1463EE215DD027BeCa91a23a07Db6aB595B577",
    // "MOPNGovernanceFacet": "0x7817D25c94cD2176C6b476179314DBa63ca6eb70",
    // "MOPNDataFacet": "0x830CeA4BBb37479491700093C38d9A8084914AFe"
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
