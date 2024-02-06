/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

const deployed = {
  'ERC6551Registry': '0x2e93D2726F80aC513A173efcF9E2dcd7659B03bc',
  'MOPNERC6551AccountHelper': '0xc6f2a4878820Dcd21d573B6cF6bB77A7a52b64C6',
  'MOPNERC6551Account': '0x8891131D3461089719C419Def1257C94e5aab2fe',
  'MOPNERC6551AccountProxy': '0xAc533454Aa767253e517530f1aB8eBeffc69D774',
  'DiamondCutFacet': '0xe917a186cadCF0FEf7016A024516c22F1C62D9b6',
  'MOPNDiamond':'0xF4b9a32b5CFc3E74a4d6eC226221Fc33e0CB274F',
  'MOPNBomb': '0x9D7597Fa84F316B9ABcD3b8d98ff9DcEcF8dDbd5',
  'MOPNToken': '0x93e1aAc24199aA32D5E3CE3C8DAF7c92AFcF7eAD',
  'MOPNCollectionVault': '0x67297b46f5FbE1F87c655285d28C08d075984129',
  'MOPNLand': '0xD0f8Ed5fD55Cb02C80727841280441550c51b7eF',
  'DiamondInit': '0x0E9b03E39E0e054c569D6867c55b8ebA0c5d9057',
  'DiamondLoupeFacet': '0x306a6913053eaee62775B508941adaC1ab29999A',
  'OwnershipFacet': '0x767935D5f706a16B1909A45828711b7310ac69b9',
  'MOPNFacet': '0xa3628DA3EDE33d0d0C6E509626c01E3Bb2528dA2',
  'MOPNAuctionHouseFacet': '0x65803D0723ed015a7E756D7Fd90509B21bcd46ff',
  'MOPNGovernanceFacet': '0xcDF6DB9d2B01d695357e56125Bf93Caf93727c7A',
  'MOPNSettlementFacet': '0x78e68a087753AD66CfC67671709e5BC63b7D960e',
  'MOPNDataFacet': '0x7e9d519EE92EF4FACF09DC5F8A0CD51D01cbC9a8'
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
