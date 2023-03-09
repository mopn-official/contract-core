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
    "0xDc075087F4a0088BABD6220000A3c8Cf57018511"
  );
  console.log("TileMath:", tileMath.address);

  console.log("deploy NFTSVG...");
  // const NFTSVG = await ethers.getContractFactory("NFTSVG");
  // const nftsvg = await NFTSVG.deploy({
  //   gasLimit: 5000000,
  // });
  // console.log(nftsvg.deployTransaction.hash);
  // await nftsvg.deployed();
  const nftsvg = await ethers.getContractAt("NFTSVG", "0xC9435cccE0069DE0Cc2094f7A36f997da13f00B6");
  console.log("NFTSVG:", nftsvg.address);

  console.log("deploy NFTMetaData...");
  // const NFTMetaData = await ethers.getContractFactory("NFTMetaData", {
  //   libraries: {
  //     NFTSVG: nftsvg.address,
  //     TileMath: tileMath.address,
  //   },
  // });
  // const nftmetadata = await NFTMetaData.deploy();
  // console.log(nftmetadata.deployTransaction.hash);
  // await nftmetadata.deployed();
  const nftmetadata = await ethers.getContractAt(
    "NFTMetaData",
    "0x3EE256Eeef106798ED679a17A38d475840213Fac"
  );
  console.log("NFTMetaData:", nftmetadata.address);

  console.log("deploy LandMetaDataRenderSolo...");
  // const LandMetaDataRenderSolo = await ethers.getContractFactory("LandMetaDataRenderSolo", {
  //   libraries: {
  //     NFTMetaData: nftmetadata.address,
  //     TileMath: tileMath.address,
  //   },
  // });
  // const render = await LandMetaDataRenderSolo.deploy();
  // console.log(render.deployTransaction.hash);
  // await render.deployed();
  const render = await ethers.getContractAt(
    "LandMetaDataRenderSolo",
    "0x21a9715a0c4687b18FeF02e1a51fdca30191A153"
  );
  console.log("LandMetaDataRenderSolo:", render.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
