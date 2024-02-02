const MOPNMath = require("../test/MOPNMath.js");
const { ethers } = require('hardhat');

let mopnFacet
  let mopnDataFacet
  let mopnerc6551accountproxy
  let mopnerc6551accounthelper

let 
    accounts = [],
    tiles = {};

async function move() {
  let diamondAddress
  let contractOwner
  const addresses = []

    const signers = await ethers.getSigners()
    contractOwner = signers[0]

    diamondAddress = '0x7155cCCc8C7727A9F6cE5EebB3Fabe1AdA009347';
    mopnFacet = await ethers.getContractAt('MOPNFacet', diamondAddress)
    mopnDataFacet = await ethers.getContractAt('MOPNDataFacet', diamondAddress)
    mopnerc6551accountproxy = await ethers.getContractAt('MOPNERC6551AccountProxy', await mopnDataFacet.ERC6551AccountProxy())
    mopnerc6551accounthelper = await ethers.getContractAt('MOPNERC6551AccountHelper', await mopnDataFacet.ERC6551AccountHelper()) 
    console.log(mopnerc6551accountproxy.address)

    const testnft = await ethers.getContractAt('IERC721','0xf1c90054fce8109854124b0c5f2c5de2b982b96a')
    console.log(testnft.address )
    
    const account = await mopnerc6551accounthelper.computeAccount(
      mopnerc6551accountproxy.address,
      168587773,
      testnft.address,
      12277,
      0
    );

    console.log("account", account);

    const accountContract = await ethers.getContractAt('MOPNERC6551Account', "0x8e2dDd25BDA74D3Dd81b547ec27984C800721f54");

    console.log("account info", await accountContract.token());
    console.log("account info", await mopnDataFacet.getAccountData(account));

    // await deployAccountNFT( testnft.address, 12277, 10001002, 0);
  
}

const deployAccountNFT = async (tokenContract, tokenId, coordinate, landId) => {
  const account = await mopnerc6551accounthelper.computeAccount(
    await mopnerc6551accountproxy.address,
    31337,
    tokenContract,
    tokenId,
    0
  );
  console.log("account move", account);
  accounts.push(account);
  const tx = await mopnFacet
    .moveToNFT(
      tokenContract,
      tokenId,
      coordinate,
      landId,
      await getMoveToTilesAccounts(coordinate),
      "0x"
    );
  await tx.wait();

  tiles[coordinate] = account;
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

if (require.main === module) {
  move()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}