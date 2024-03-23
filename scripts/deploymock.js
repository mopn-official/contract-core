/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')

const deployed = {
  "MOCKNFT": "0x62969F19D4d0eC787d51F63dd892598601815c54",
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

  const mocknft = await deployContract('MOCKNFT');
  console.log("mock nft address: " , mocknft.address)

  const tx = await mocknft.initialize(
    'BoredApeYachtClub',
    'BAYC',
    contractOwner.address,
    'ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/',
    ''
  );
  await tx.wait();
  console.log("mock nft initialized");
}


  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
