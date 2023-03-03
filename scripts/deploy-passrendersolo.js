const { ethers } = require("hardhat");

async function main() {
  console.log("deploy TileMath...");
  // const TileMath = await ethers.getContractFactory("TileMath");
  // const tileMath = await TileMath.deploy({
  //   gasLimit: 5000000,
  // });
  // console.log(tileMath.deployTransaction.hash);
  // await tileMath.deployed();
  const tileMath = await ethers.getContractAt(
    "TileMath",
    "0xd1273be7de38269322fef74d6c48857aaac0a3fa"
  );
  console.log("TileMath:", tileMath.address);

  console.log("deploy NFTSVG...");
  const NFTSVG = await ethers.getContractFactory("NFTSVG");
  const nftsvg = await NFTSVG.deploy({
    gasLimit: 5000000,
  });
  console.log(nftsvg.deployTransaction.hash);
  await nftsvg.deployed();
  // const nftsvg = await ethers.getContractAt("NFTSVG", "0x0036E1CEaC14cA79DdBa736b202d6C9E0863F4dD");
  console.log("NFTSVG:", nftsvg.address);

  console.log("deploy NFTMetaData...");
  const NFTMetaData = await ethers.getContractFactory("NFTMetaData", {
    libraries: {
      NFTSVG: nftsvg.address,
      TileMath: tileMath.address,
    },
  });
  const nftmetadata = await NFTMetaData.deploy();
  console.log(nftmetadata.deployTransaction.hash);
  await nftmetadata.deployed();
  // const nftmetadata = await ethers.getContractAt(
  //   "NFTMetaData",
  //   "0xD8Fce18eb003dC9AE6DC65dd0848Bc4A9694C035"
  // );
  console.log("NFTMetaData:", nftmetadata.address);

  console.log("deploy LandMetaDataRenderSolo...");
  const LandMetaDataRenderSolo = await ethers.getContractFactory("LandMetaDataRenderSolo", {
    libraries: {
      NFTMetaData: nftmetadata.address,
      TileMath: tileMath.address,
    },
  });
  const render = await LandMetaDataRenderSolo.deploy();
  console.log(render.deployTransaction.hash);
  await render.deployed();
  // const render = await ethers.getContractAt(
  //   "LandMetaDataRenderSolo",
  //   "0x6a77e7c1b144EAd03E2f4e240dBB0e723466D6Ef"
  // );
  console.log("LandMetaDataRenderSolo:", render.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
