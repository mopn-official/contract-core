/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')
const MOPNMath = require("./MOPNMath");

const { deployDiamond } = require('../scripts/deploy.js')

const { assert } = require('chai');
const { ethers } = require('hardhat');

describe('DiamondTest', async function () {
  let diamondAddress
  let diamondCutFacet
  let diamondLoupeFacet
  let ownershipFacet
  let mopnFacet
  let mopnAuctionHouseFacet
  let mopnGovernanceFacet
  let mopnSettlement
  let mopnDataFacet
  let mopnerc6551accountproxy
  let mopnerc6551accounthelper
  let tx
  let receipt
  let result
  let contractOwner
  const addresses = []

  let 
    accounts = [],
    tiles = {};

  before(async function () {
    const accounts = await ethers.getSigners()
    contractOwner = accounts[0]

    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
    mopnFacet = await ethers.getContractAt('MOPNFacet', diamondAddress)
    mopnAuctionHouseFacet = await ethers.getContractAt('MOPNAuctionHouseFacet', diamondAddress)
    mopnGovernanceFacet = await ethers.getContractAt('MOPNGovernanceFacet', diamondAddress)
    mopnDataFacet = await ethers.getContractAt('MOPNDataFacet', diamondAddress)
    mopnerc6551accountproxy = await ethers.getContractAt('MOPNERC6551AccountProxy', await mopnDataFacet.ERC6551AccountProxy())
    mopnerc6551accounthelper = await ethers.getContractAt('MOPNERC6551AccountHelper', await mopnDataFacet.ERC6551AccountHelper()) 
  })

  it('should have seven facets -- call to facetAddresses function', async () => {
    for (const address of await diamondLoupeFacet.facetAddresses()) {
      addresses.push(address)
    }

    assert.equal(addresses.length, 7)
  })

  it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
    let selectors = getSelectors(diamondCutFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(diamondLoupeFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(ownershipFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(mopnFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(mopnAuctionHouseFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[4])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(mopnGovernanceFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[5])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(mopnDataFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[6])
    assert.sameMembers(result, selectors)
  })

  it('selectors should be associated to facets correctly -- multiple calls to facetAddress function', async () => {
    assert.equal(
      addresses[0],
      await diamondLoupeFacet.facetAddress('0x1f931c1c')
    )
    assert.equal(
      addresses[1],
      await diamondLoupeFacet.facetAddress('0xcdffacc6')
    )
    assert.equal(
      addresses[1],
      await diamondLoupeFacet.facetAddress('0x01ffc9a7')
    )
    assert.equal(
      addresses[2],
      await diamondLoupeFacet.facetAddress('0xf2fde38b')
    )
  })

  it('test move to nft', async () => {
    
    const MOCKNFT = await ethers.getContractFactory('MOCKNFT')
    const testnft = await MOCKNFT.deploy()
    await testnft.deployed()
    console.log(testnft.address )
    
    tx = await testnft.initialize("MOCKNFT", "MOCKNFT", contractOwner.address, "", "");
    await tx.wait();

    tx = await testnft.mint(1);
    await tx.wait();
    
    const account = await deployAccountNFT( testnft.address, 0, 10001000, 0);

    const accountContract = await ethers.getContractAt('MOPNERC6551Account', account);

    console.log("account info", await accountContract.token());
    console.log("account info", await mopnDataFacet.getAccountData(account));
  })

  const deployAccountNFT = async (tokenContract, tokenId, coordinate, landId) => {
    const account = await mopnerc6551accounthelper.computeAccount(
      await mopnerc6551accountproxy.address,
      ethers.utils.hexZeroPad("0x", 32),
      31337,
      tokenContract,
      tokenId
    );
    console.log("account move", account);
    accounts.push(account);
    const owners = await ethers.getSigners();
    const tx = await mopnFacet.connect(owners[1])
      .moveToNFT(
        tokenContract,
        tokenId,
        coordinate,
        landId,
        await getMoveToTilesAccounts(coordinate),
      );
    await tx.wait();

    tiles[coordinate] = account;
    return account;
  };

  const getMoveToTilesAccounts = async (tileCoordinate) => {
    let tileaccounts = [];
    tileaccounts[0] = tiles[tileCoordinate] ? tiles[tileCoordinate] : ethers.constants.AddressZero;
    tileCoordinate++;
    for (let i = 0; i < 18; i++) {
      tileaccounts[i + 1] = tiles[tileCoordinate] ? tiles[tileCoordinate] : ethers.constants.AddressZero;
      if (i == 5) {
        tileCoordinate += 10001;
      } else if (i < 5) {
        tileCoordinate = MOPNMath.neighbor(tileCoordinate, i);
      } else {
        tileCoordinate = MOPNMath.neighbor(tileCoordinate, Math.floor((i - 6) / 2));
      }
    }
    return tileaccounts;
  };
})
