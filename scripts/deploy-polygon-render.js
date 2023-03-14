const { ethers } = require("hardhat");

async function main() {
  console.log("deploy MOPNLand...");
  // const MOPNLand = await ethers.getContractFactory("MOPNLand");
  // const land = await MOPNLand.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + land.deployTransaction.hash);
  // await land.deployed();
  const land = await ethers.getContractAt("MOPNLand", "0xBFe8B57039D81F8e841bF123309635AE195499D6");
  console.log("MOPNLand", land.address);

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
  // const NFTMetaData = await ethers.getContractFactory("NFTMetaData", {
  //   libraries: {
  //     NFTSVG: nftsvg.address,
  //     TileMath: tileMath.address,
  //   },
  // });
  // const nftmetadata = await NFTMetaData.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + nftmetadata.deployTransaction.hash);
  // await nftmetadata.deployed();
  const nftmetadata = await ethers.getContractAt(
    "NFTMetaData",
    "0xC9435cccE0069DE0Cc2094f7A36f997da13f00B6"
  );
  console.log("NFTMetaData:", nftmetadata.address);

  console.log("deploy LandMetaDataRender...");
  // const LandMetaDataRender = await ethers.getContractFactory("LandMetaDataRender", {
  //   libraries: {
  //     NFTMetaData: nftmetadata.address,
  //     TileMath: tileMath.address,
  //   },
  // });
  // const render = await LandMetaDataRender.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + render.deployTransaction.hash);
  // await render.deployed();
  const render = await ethers.getContractAt(
    "LandMetaDataRender",
    "0x99b858C3f57593ba9405eF8c390c588058661e8E"
  );
  console.log("LandMetaDataRender:", render.address);

  console.log("set land render...");
  const settx1 = await land.setRender(render.address);
  await settx1.wait();
  console.log("set land render done");

  console.log("set render governance...");
  const settx2 = await render.setGovernanceContract("0x5dC899e32325E5d8506c5955A5FF25906165C16C");
  await settx2.wait();
  console.log("set render governance done");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
