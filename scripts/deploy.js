const { ethers } = require("hardhat");

async function main() {
  console.log("deploy TileMath...");
  // const TileMath = await ethers.getContractFactory("TileMath");
  // const tileMath = await TileMath.deploy();
  // await tileMath.deployed();
  const tileMath = await ethers.getContractAt(
    "TileMath",
    "0xBC7DEAdB2AF96690D0Ed7B9091e77E54C60A9e01"
  );
  console.log("TileMath:", tileMath.address);

  console.log("deploy Arsenal...");
  // const Arsenal = await ethers.getContractFactory("Arsenal");
  // const arsenal = await Arsenal.deploy();
  // await arsenal.deployed();
  const arsenal = await ethers.getContractAt(
    "Arsenal",
    "0xfcAe84E58C853Aff8898E1b958cA31218bc6B364"
  );
  console.log("Arsenal", arsenal.address);

  console.log("deploy Avatar...");
  // const Avatar = await ethers.getContractFactory("Avatar", {
  //   libraries: {
  //     TileMath: tileMath.address,
  //   },
  // });
  // const avatar = await Avatar.deploy();
  // await avatar.deployed();
  const avatar = await ethers.getContractAt("Avatar", "0xe46E1DA50645448Baf45DA22AaFB45b24f1Db4B9");
  console.log("Avatar", avatar.address);

  console.log("deploy Bomb...");
  // const Bomb = await ethers.getContractFactory("Bomb");
  // const bomb = await Bomb.deploy();
  // await bomb.deployed();
  const bomb = await ethers.getContractAt("Bomb", "0x2DE1A041fDe1326E26aaC085562A9249Ec287409");
  console.log("Bomb", bomb.address);

  console.log("deploy Energy...");
  // const Energy = await ethers.getContractFactory("Energy");
  // const energy = await Energy.deploy("$Energy", "MOPNE");
  // await energy.deployed();
  const energy = await ethers.getContractAt("Energy", "0x04B07B4ec49C89CF59D3FF7e184365402A5aFBEF");
  console.log("Energy", energy.address);

  console.log("deploy Governance...");
  // const Governance = await ethers.getContractFactory("Governance");
  // const governance = await Governance.deploy(0, true);
  // await governance.deployed();
  const governance = await ethers.getContractAt(
    "Governance",
    "0xDd9c8Dc7A9Ed13E12253D72FBCc79555ed6811ce"
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
  const map = await ethers.getContractAt("Map", "0xBb80001381618Bb7AD4378B5dFb428ce7b4484A2");
  console.log("Map", map.address);

  // console.log("transfer Energy owner...");
  // const energytransownertx = await energy.transferOwnership(governance.address);
  // await energytransownertx.wait();
  // console.log("done");

  // console.log("transfer Bomb owner...");
  // const bombtransownertx = await bomb.transferOwnership(governance.address);
  // await bombtransownertx.wait();
  // console.log("done");

  console.log("Governance update MOPN Contracts");
  const governancesetmopntx = await governance.updateMOPNContracts(
    arsenal.address,
    avatar.address,
    bomb.address,
    energy.address,
    map.address,
    map.address
  );
  await governancesetmopntx.wait();
  console.log("done");

  console.log("Arsenal update Governance Contract");
  const arsenalsetgovernancecontracttx = await arsenal.setGovernanceContract(governance.address);
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
