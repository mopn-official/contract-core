const { ethers } = require("hardhat");

async function main() {
  console.log("deploy Avatar...");
  const Avatar = await ethers.getContractFactory("Avatar", {
    libraries: {
      TileMath: tileMath.address,
    },
  });
  const avatar = await Avatar.deploy();
  await avatar.deployed();
  console.log("Avatar", avatar.address);

  const governance = await ethers.getContractAt(
    "Governance",
    "0xC024f35a45D7a50f3C3092ab1e067E5623e56F03"
  );

  console.log("set whitelist require...");
  const setWhiteListRequiretx = await governance.setWhiteListRequire(false);
  await setWhiteListRequiretx.wait();
  console.log("done");

  console.log("Governance update Avatar Contract");
  const governancesetavatartx = await governance.updateAvatarContract(avatar.address);
  await governancesetavatartx.wait();
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
