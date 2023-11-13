const { ethers, config } = require("hardhat");

async function main() {
  const mopndata = await ethers.getContractAt(
    "MOPNData",
    "0x1716417A14CC225Ab0A5Dab6A432B4d319D1c723"
  );
  const amount = await mopndata.getWalletStakingMTs(
    ["0x41ada2d9dae3628b252b647e3c25dd42523d5cc2", "0x3d05623032515a4bf171c90301260e4ea7715cb4"],
    { from: "0x3FFE98b5c1c61Cc93b684B44aA2373e1263Dd4A4" }
  );
  console.log(amount);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
