const { ethers, config } = require("hardhat");

async function main() {
  const nft = await ethers.getContractAt("IERC721", "0xc4CB1a6897e0083B0C5fdFFbBcb07cF1cf5DCE50");
  const owner = await nft.ownerOf(1);
  console.log(owner);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
