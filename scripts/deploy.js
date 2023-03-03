const { ethers } = require("hardhat");

async function main() {
  console.log("deploy TileMath...");
  // const TileMath = await ethers.getContractFactory("TileMath");
  // const tileMath = await TileMath.deploy();
  // await tileMath.deployed();
  const tileMath = await ethers.getContractAt(
    "TileMath",
    "0xd1273be7de38269322fef74d6c48857aaac0a3fa"
  );
  console.log("TileMath:", tileMath.address);

  console.log("deploy AuctionHouse...");
  // const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
  // const auctionHouse = await AuctionHouse.deploy(1677825096, 1677825096);
  // await auctionHouse.deployed();
  const auctionHouse = await ethers.getContractAt(
    "AuctionHouse",
    "0x949F682404d26dB4ad973d775B2D35447CE5de9b"
  );
  console.log("AuctionHouse", auctionHouse.address);

  console.log("deploy Avatar...");
  // const Avatar = await ethers.getContractFactory("Avatar", {
  //   libraries: {
  //     TileMath: tileMath.address,
  //   },
  // });
  // const avatar = await Avatar.deploy();
  // await avatar.deployed();
  const avatar = await ethers.getContractAt("Avatar", "0x59865373f6168f2fA498485174E48be8D46b1EB0");
  console.log("Avatar", avatar.address);

  console.log("deploy Bomb...");
  // const Bomb = await ethers.getContractFactory("Bomb");
  // const bomb = await Bomb.deploy();
  // await bomb.deployed();
  const bomb = await ethers.getContractAt("Bomb", "0x9c81Dff5ad4a03F8A2a29b7A27ff729c7870d11E");
  console.log("Bomb", bomb.address);

  console.log("deploy Energy...");
  const Energy = await ethers.getContractFactory("Energy");
  const energy = await Energy.deploy("$Energy", "MOPNE");
  await energy.deployed();
  // const energy = await ethers.getContractAt("Energy", "0x38D7cb5c9B0f0495fb189D703d7960f0d3e12FB5");
  console.log("Energy", energy.address);

  console.log("deploy Governance...");
  // const Governance = await ethers.getContractFactory("Governance");
  // const governance = await Governance.deploy(0, true);
  // await governance.deployed();
  const governance = await ethers.getContractAt(
    "Governance",
    "0x5Bc47286dB347F15526cE342076548a4235DDE0c"
  );
  console.log("Governance", governance.address);

  console.log("deploy Map...");
  // const Map = await ethers.getContractFactory("Map", {
  //   libraries: {
  //     TileMath: tileMath.address,
  //   },
  // });
  // const map = await Map.deploy();
  // await map.deployed();
  const map = await ethers.getContractAt("Map", "0xEe275c38F035Aac08C24ebB44B05Af6cDEFDF3Ff");
  console.log("Map", map.address);

  console.log("transfer Energy owner...");
  const energytransownertx = await energy.transferOwnership(governance.address);
  await energytransownertx.wait();
  console.log("done");

  console.log("transfer Bomb owner...");
  const bombtransownertx = await bomb.transferOwnership(governance.address);
  await bombtransownertx.wait();
  console.log("done");

  console.log("Governance update MOPN Contracts");
  const governancesetmopntx = await governance.updateMOPNContracts(
    auctionHouse.address,
    avatar.address,
    bomb.address,
    energy.address,
    map.address,
    map.address
  );
  await governancesetmopntx.wait();
  console.log("done");

  console.log("AuctionHouse update Governance Contract");
  const arsenalsetgovernancecontracttx = await auctionHouse.setGovernanceContract(
    governance.address
  );
  await arsenalsetgovernancecontracttx.wait();
  console.log("done");

  console.log("Avatar update Governance Contract");
  const avatarsetgovernancecontracttx = await avatar.setGovernanceContract(governance.address);
  await avatarsetgovernancecontracttx.wait();
  console.log("done");

  console.log("Map update Governance Contract");
  const mapsetgovernancecontracttx = await map.setGovernanceContract(governance.address);
  await mapsetgovernancecontracttx.wait();
  console.log("done");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
