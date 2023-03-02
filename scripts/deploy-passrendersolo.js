const { ethers } = require("hardhat");

async function main() {
  console.log("deploy TileMath...");
  const TileMath = await ethers.getContractFactory("TileMath");
  const tileMath = await TileMath.deploy({
    gasLimit: 5000000,
  });
  console.log(tileMath.deployTransaction.hash);
  await tileMath.deployed();
  // const tileMath = await ethers.getContractAt(
  //   "TileMath",
  //   "0x0AE3768a53d1a7Ab15290A294018DE747725b2da"
  // );
  console.log("TileMath:", tileMath.address);

  console.log("deploy NFTSVG...");
  const NFTSVG = await ethers.getContractFactory("NFTSVG");
  const nftsvg = await NFTSVG.deploy();
  console.log(nftsvg.deployTransaction.hash);
  await nftsvg.deployed();
  // const nftsvg = await ethers.getContractAt("NFTSVG", "0x74D483003Cada124Deb24744E786EbE73d9c3cDb");
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
  //   "0xe1C482EB374318ab5e5bCE34EcDBd3D1B8546f35"
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
  //   "0x336fD0cA0406B3A57d9519b2767554ff9E3b3CAf"
  // );
  console.log("LandMetaDataRenderSolo:", render.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
