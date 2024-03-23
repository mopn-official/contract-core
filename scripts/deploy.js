/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

const deployed = {
  "ERC6551Registry": "0x000000006551c19487814612e58FE06813775758",
  "MOPNERC6551AccountHelper": "0xCcDB391C6Fe158006035B3aA2eb1206D2778d15e",
  "MOPNERC6551Account": "0xb19b9cc59506046C10EFdB151FBC68F6E3ac0456",
  "MOPNERC6551AccountProxy": "0x306b9652ADd38A398De97ee577d1E09D8BCD8CeE",
  "DiamondCutFacet": "0xba7Bf786C4fBCC35EE6Dc427895ad0DeaD6EE1Cf",
  "MOPNDiamond": "0x038828FA4bFaB1275397ABBAbf54456e76C34083",
  "MOPNBomb": "0x45231c9668289A0C7C434660146eCF48Ef872F4c",
  "MOPNToken": "0xD6e06BBcffdf88aa40D1116Afa42EF1457B0029E",
  "MOPNCollectionVault": "0x3817Ee5BfA85d1f895136918B9D77E4304C7D642",
  "MOPNLand": "0xC99764F086BC5B4Cd140E4723414335738916706",
  "MOPNGasVault": "0xbc25d37Cfea02E78DeD904c02081AA0B524d26F2",
  "DiamondInit": "0x68cA187194073A7949DC9f0160d9e09839A35520",
  "DiamondLoupeFacet": "0x797059Baa33DcFCD613397d6EfD5D3af074B3c3B",
  "OwnershipFacet": "0xdd5c4eE5d59B87b713bD93E6C54C14eb0CDF67D6",
  "MOPNFacet": "0xb12c0b1d96Dc3F4FbD72FE80ace1433c5C500dA0",
  "MOPNAuctionHouseFacet": "0x7F17aD55706558D0DC2028aBC1CfBCBF95d2d70b",
  "MOPNGovernanceFacet": "0x171F4Da1EAd3eC43765eB3f3E55BAa35f1412B53",
  "MOPNDataFacet": "0xBE76F97a8E5c8B6BC683DADd5dC3d635121a0304"
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
  // for (const FacetName of FacetNames) {
  //   const facet = await deployContract(FacetName)
  //   cut.push({
  //     facetAddress: facet.address,
  //     action: FacetCutAction.Add,
  //     functionSelectors: getSelectors(facet)
  //   })
  // }

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

  return diamond.address;

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
