const { ethers } = require("hardhat");

async function main() {
  console.log("deploy TileMath...");
  //   const TileMath = await ethers.getContractFactory("TileMath");
  //   const tileMath = await TileMath.deploy();
  //   await tileMath.deployed();
  let tileMath = { address: "0x74D483003Cada124Deb24744E786EbE73d9c3cDb" };
  console.log("TileMath:", tileMath.address);

  console.log("deploy Arsenal...");
  //   const Arsenal = await ethers.getContractFactory("Arsenal");
  //   const arsenal = await Arsenal.deploy();
  //   await arsenal.deployed();
  let arsenal = { address: "0xe1C482EB374318ab5e5bCE34EcDBd3D1B8546f35" };
  console.log("Arsenal", arsenal.address);

  console.log("deploy Avatar...");
  const Avatar = await ethers.getContractFactory("Avatar", {
    libraries: {
      TileMath: tileMath.address,
    },
  });
  const avatar = await Avatar.deploy();
  await avatar.deployed();
  console.log("Avatar", avatar.address);

  console.log("deploy Bomb...");
  const Bomb = await ethers.getContractFactory("Bomb");
  const bomb = await Bomb.deploy();
  await bomb.deployed();
  console.log("Bomb", bomb.address);

  console.log("deploy Energy...");
  const Energy = await ethers.getContractFactory("Energy");
  const energy = await Energy.deploy("$Energy", "MOPNE");
  await energy.deployed();
  console.log("Energy", energy.address);

  console.log("deploy Governance...");
  const Governance = await ethers.getContractFactory("Governance");
  const governance = await Governance.deploy(0, true);
  await governance.deployed();
  console.log("Governance", governance.address);

  console.log("deploy Map...");
  const Map = await ethers.getContractFactory("Map", {
    libraries: {
      TileMath: tileMath.address,
    },
  });
  const map = await Map.deploy();
  await map.deployed();
  console.log("Map", map.address);

  console.log("transfer Energy owner...");
  const energytransownertx = await energy.transferOwnership(governance.address);
  await energytransownertx.wait();
  console.log("done");

  console.log("transfer Bomb owner...");
  const bombtransownertx = await bomb.transferOwnership(governance.address);
  await bombtransownertx.wait();
  console.log("done");

  console.log("Governance update Arsenal Contract");
  const governancesetarsenaltx = await governance.updateArsenalContract(arsenal.address);
  await governancesetarsenaltx.wait();
  console.log("done");

  console.log("Governance update Avatar Contract");
  const governancesetavatartx = await governance.updateAvatarContract(avatar.address);
  await governancesetavatartx.wait();
  console.log("done");

  console.log("Governance update Bomb Contract");
  const governancesetbombtx = await governance.updateBombContract(bomb.address);
  await governancesetbombtx.wait();
  console.log("done");

  console.log("Governance update Energy Contract");
  const governancesetenergytx = await governance.updateEnergyContract(energy.address);
  await governancesetenergytx.wait();
  console.log("done");

  console.log("Governance update Map Contract");
  const governancesetmaptx = await governance.updateMapContract(map.address);
  await governancesetmaptx.wait();
  console.log("done");

  console.log("Governance update Pass Contract");
  const governancesetpasstx = await governance.updatePassContract(map.address);
  await governancesetpasstx.wait();
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
