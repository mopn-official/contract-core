const { ethers } = require("hardhat");

async function main() {
  console.log("deploy TileMath...");
  // const TileMath = await ethers.getContractFactory("TileMath");
  // const tileMath = await TileMath.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + tileMath.deployTransaction.hash);
  // await tileMath.deployed();
  const tileMath = await ethers.getContractAt(
    "TileMath",
    "0xBC7DEAdB2AF96690D0Ed7B9091e77E54C60A9e01"
  );
  console.log("TileMath:", tileMath.address);

  console.log("deploy AuctionHouse...");
  // const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
  // const auctionHouse = await AuctionHouse.deploy(1677825096, 1677825096);
  // console.log("https://mumbai.polygonscan.com/tx/" + auctionHouse.deployTransaction.hash);
  // await auctionHouse.deployed();
  const auctionHouse = await ethers.getContractAt(
    "AuctionHouse",
    "0xfcAe84E58C853Aff8898E1b958cA31218bc6B364"
  );
  console.log("AuctionHouse", auctionHouse.address);

  console.log("deploy Avatar...");
  // const Avatar = await ethers.getContractFactory("Avatar", {
  //   libraries: {
  //     TileMath: tileMath.address,
  //   },
  // });
  // const avatar = await Avatar.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + avatar.deployTransaction.hash);
  // await avatar.deployed();
  const avatar = await ethers.getContractAt("Avatar", "0x14C0344AAa352a80F053670FbB2Ca1879729148b");
  console.log("Avatar", avatar.address);

  console.log("deploy Bomb...");
  // const Bomb = await ethers.getContractFactory("Bomb");
  // const bomb = await Bomb.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + bomb.deployTransaction.hash);
  // await bomb.deployed();
  const bomb = await ethers.getContractAt("Bomb", "0xee5A0801D51feC7c54A5ac03E6E84213AA08Bd80");
  console.log("Bomb", bomb.address);

  console.log("deploy MOPNToken...");
  // const MOPNToken = await ethers.getContractFactory("MOPNToken");
  // const mt = await MOPNToken.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + mt.deployTransaction.hash);
  // await mt.deployed();
  const mt = await ethers.getContractAt("MOPNToken", "0x4C0b27272160D8349c1c1A46ef4930D72f03B9fB");
  console.log("MOPNToken", mt.address);

  console.log("deploy Governance...");
  // const Governance = await ethers.getContractFactory("Governance");
  // const governance = await Governance.deploy(0);
  // console.log("https://mumbai.polygonscan.com/tx/" + governance.deployTransaction.hash);
  // await governance.deployed();
  const governance = await ethers.getContractAt(
    "Governance",
    "0x5dC899e32325E5d8506c5955A5FF25906165C16C"
  );
  console.log("Governance", governance.address);

  console.log("deploy Map...");
  // const Map = await ethers.getContractFactory("Map", {
  //   libraries: {
  //     TileMath: tileMath.address,
  //   },
  // });
  // const map = await Map.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + map.deployTransaction.hash);
  // await map.deployed();
  const map = await ethers.getContractAt("Map", "0x42E627CD652Caf8340bF8753bB1d436eD1457C04");
  console.log("Map", map.address);

  console.log("deploy NFTSVG...");
  // const NFTSVG = await ethers.getContractFactory("NFTSVG");
  // const nftsvg = await NFTSVG.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + nftsvg.deployTransaction.hash);
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
    "0xD05aD9C85237c5660c9dB49ab3F5961F51426f53"
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
    "0xEbf86fC7eec339Ed7A58F44fD7931800469dA3b2"
  );
  console.log("LandMetaDataRender:", render.address);

  // console.log("deploy LandMetaDataRenderSolo...");
  // const LandMetaDataRenderSolo = await ethers.getContractFactory("LandMetaDataRenderSolo", {
  //   libraries: {
  //     NFTMetaData: nftmetadata.address,
  //     TileMath: tileMath.address,
  //   },
  // });
  // const render = await LandMetaDataRenderSolo.deploy();
  // console.log(render.deployTransaction.hash);
  // await render.deployed();
  // const render = await ethers.getContractAt(
  //   "LandMetaDataRenderSolo",
  //   "0x21a9715a0c4687b18FeF02e1a51fdca30191A153"
  // );
  // console.log("LandMetaDataRenderSolo:", render.address);

  console.log("deploy MOPNLand...");
  // const MOPNLand = await ethers.getContractFactory("MOPNLand");
  // const land = await MOPNLand.deploy();
  // console.log("https://mumbai.polygonscan.com/tx/" + land.deployTransaction.hash);
  // await land.deployed();
  const land = await ethers.getContractAt("MOPNLand", "0xBFe8B57039D81F8e841bF123309635AE195499D6");
  console.log("MOPNLand", land.address);

  // console.log("update land render...");
  // const landrendertx = await land.setMetaDataRender(render.address);
  // await landrendertx.wait();
  // console.log("done");

  console.log("deploy TESTNFT...");
  // const TESTNFT = await ethers.getContractFactory("TESTNFT");
  // const testnft = await TESTNFT.deploy();
  // await testnft.deployed();
  const testnft = await ethers.getContractAt(
    "TESTNFT",
    "0x75e38249815F1697f1116D9ab10a3Df0CD5480b9"
  );
  console.log("TESTNFT", testnft.address);

  console.log("deploy TESTNFT1...");
  // const TESTNFT1 = await ethers.getContractFactory("TESTNFT");
  // const testnft1 = await TESTNFT1.deploy();
  // await testnft1.deployed();
  const testnft1 = await ethers.getContractAt(
    "TESTNFT",
    "0x75e38249815F1697f1116D9ab10a3Df0CD5480b9"
  );
  console.log("TESTNFT1", testnft1.address);

  console.log("deploy TESTNFT2...");
  // const TESTNFT2 = await ethers.getContractFactory("TESTNFT");
  // const testnft2 = await TESTNFT2.deploy();
  // await testnft2.deployed();
  const testnft2 = await ethers.getContractAt(
    "TESTNFT",
    "0x75e38249815F1697f1116D9ab10a3Df0CD5480b9"
  );
  console.log("TESTNFT2", testnft2.address);

  console.log("transfer MOPNToken owner...");
  const energytransownertx = await mt.transferOwnership(governance.address);
  await energytransownertx.wait();
  console.log("done");

  console.log("transfer Bomb owner...");
  const bombtransownertx = await bomb.transferOwnership(governance.address);
  await bombtransownertx.wait();
  console.log("done");

  console.log("Governance update MOPN Contracts");
  const governancesetmopntx = await governance.updateMOPNContracts(
    auctionHouse.address,
    avatar.address,
    bomb.address,
    mt.address,
    map.address,
    land.address
  );
  await governancesetmopntx.wait();
  console.log("done");

  console.log("AuctionHouse update Governance Contract");
  const ahsetgovernancecontracttx = await auctionHouse.setGovernanceContract(governance.address);
  await ahsetgovernancecontracttx.wait();
  console.log("done");

  console.log("Avatar update Governance Contract");
  const avatarsetgovernancecontracttx = await avatar.setGovernanceContract(governance.address);
  await avatarsetgovernancecontracttx.wait();
  console.log("done");

  console.log("Map update Governance Contract");
  const mapsetgovernancecontracttx = await map.setGovernanceContract(governance.address);
  await mapsetgovernancecontracttx.wait();
  console.log("done");

  console.log("Land Render update Governance Contract");
  const rendersetgovernancecontracttx = await render.setGovernanceContract(governance.address);
  await rendersetgovernancecontracttx.wait();
  console.log("done");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
