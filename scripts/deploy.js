/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

const deployed = {
  // 'ERC6551Registry': '0x75499b61b947782F62d634e0D577dB1F89D5676A',
  // 'MOPNERC6551AccountHelper': '0xaeaed94bEF3334b5560ba76b1e5375dD48c0EBf1',
  // 'MOPNERC6551Account': '0x0632b96A61Eb41F27D5e26c7bc5d9f5e27fb84E8',
  // 'MOPNERC6551AccountProxy': '0x2077e7EE7723C17E4302a438028746a3fb108F19',
  // 'DiamondCutFacet': '0x5Cd2f04ADD03F47C14a930500194B67DFB8d101e',
  // 'MOPNDiamond':'0x7155cCCc8C7727A9F6cE5EebB3Fabe1AdA009347',
  // 'MOPNBomb': '0x60497F2315bB150FED8B0a68db0cE9Ec763C5191',
  // 'MOPNToken': '0xAac57eF60f472c049233cBAD5141457fd6f0A2b7',
  // 'MOPNCollectionVault': '0xD8A1F515770208195BBaF35298A65745A67B3F35',
  // 'MOPNLand': '0x56ca6944407D9de07730B9c13D4e0538a9100855',
  // 'DiamondInit': '0x43BE121c7d9406A7F31a9686AfF04Fd3a781F610',
  // 'DiamondLoupeFacet': '0x5D6E58fCe321d5256b5Ad64d5c3412Fc5a81b3AB',
  // 'OwnershipFacet': '0xdFD9316530fF3f1334067AD3e0b5a7e283De3C34',
  // 'MOPNFacet': '0x757d3fCeeC4ddD95376779e4f68c552085a9D364',
  // 'MOPNAuctionHouseFacet': '0xbAb242b6E3519e37405C6d0fE8EC852a191eE616',
  // 'MOPNGovernanceFacet': '0x8D2c9f18E68c6bEcbf29709C43a49064C517d47F',
  // 'MOPNDataFacet': '0x62635940bD861e5E6be098bcEb0A5B2990D1E13F'
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
    diamond.address,
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
