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
    "0xBC7DEAdB2AF96690D0Ed7B9091e77E54C60A9e01"
  );
  console.log("TileMath:", tileMath.address);

  console.log("deploy NFTSVG...");
  // const NFTSVG = await ethers.getContractFactory("NFTSVG");
  // const nftsvg = await NFTSVG.deploy({
  //   gasLimit: 5000000,
  // });
  // console.log(nftsvg.deployTransaction.hash);
  // await nftsvg.deployed();
  const nftsvg = await ethers.getContractAt("NFTSVG", "0xBb80001381618Bb7AD4378B5dFb428ce7b4484A2");
  console.log("NFTSVG:", nftsvg.address);

  console.log("deploy NFTMetaData...");
  const NFTMetaData = await ethers.getContractFactory("NFTMetaData", {
    libraries: {
      NFTSVG: nftsvg.address,
      TileMath: tileMath.address,
    },
  });
  const nftmetadata = await NFTMetaData.deploy();
  console.log("https://mumbai.polygonscan.com/tx/" + nftmetadata.deployTransaction.hash);
  await nftmetadata.deployed();
  // const nftmetadata = await ethers.getContractAt(
  //   "NFTMetaData",
  //   "0x0036E1CEaC14cA79DdBa736b202d6C9E0863F4dD"
  // );
  console.log("NFTMetaData:", nftmetadata.address);

  console.log("deploy LandMetaDataRender...");
  const LandMetaDataRender = await ethers.getContractFactory("LandMetaDataRender", {
    libraries: {
      NFTMetaData: nftmetadata.address,
      TileMath: tileMath.address,
    },
  });
  const render = await LandMetaDataRender.deploy();
  console.log("https://mumbai.polygonscan.com/tx/" + render.deployTransaction.hash);
  await render.deployed();
  // const render = await ethers.getContractAt(
  //   "LandMetaDataRender",
  //   "0xD8Fce18eb003dC9AE6DC65dd0848Bc4A9694C035"
  // );
  console.log("LandMetaDataRender:", render.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
