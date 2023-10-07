const { ethers } = require("hardhat");
const { getContractAddress } = require("./MOPNContract");

async function main() {
  console.log(await getContractAddress("MOPN"));
  console.log(await getContractAddress("MOPNGovernance"));
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
