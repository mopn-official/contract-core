const { ethers } = require("hardhat");

async function main() {
  console.log("deploy TileMath...");
  // const TileMath = await ethers.getContractFactory("TileMath");
  // const tileMath = await TileMath.deploy();
  // console.log("https://goerli.etherscan.io/tx/" + tileMath.deployTransaction.hash);
  // await tileMath.deployed();
  const tileMath = await ethers.getContractAt(
    "TileMath",
    "0xDc075087F4a0088BABD6220000A3c8Cf57018511"
  );
  console.log("TileMath:", tileMath.address);

  console.log("deploy AuctionHouse...");
  // const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
  // const auctionHouse = await AuctionHouse.deploy(1677825096, 1677825096);
  // console.log("https://goerli.etherscan.io/tx/" + auctionHouse.deployTransaction.hash);
  // await auctionHouse.deployed();
  const auctionHouse = await ethers.getContractAt(
    "AuctionHouse",
    "0xCfe93b0De47CD9bEd5eF4470535733CC0c862a6C"
  );
  console.log("AuctionHouse", auctionHouse.address);

  console.log("deploy Avatar...");
  // const Avatar = await ethers.getContractFactory("Avatar", {
  //   libraries: {
  //     TileMath: tileMath.address,
  //   },
  // });
  // const avatar = await Avatar.deploy();
  // console.log("https://goerli.etherscan.io/tx/" + avatar.deployTransaction.hash);
  // await avatar.deployed();
  const avatar = await ethers.getContractAt("Avatar", "0x76f054fCE60aA6555935af2Ca39a4c35C6331DA5");
  console.log("Avatar", avatar.address);

  console.log("deploy Bomb...");
  // const Bomb = await ethers.getContractFactory("Bomb");
  // const bomb = await Bomb.deploy();
  // console.log("https://goerli.etherscan.io/tx/" + bomb.deployTransaction.hash);
  // await bomb.deployed();
  const bomb = await ethers.getContractAt("Bomb", "0x9eF0A20Bea4068Ceb5191afdAEC07eA8A96c7fD2");
  console.log("Bomb", bomb.address);

  console.log("deploy MOPNToken...");
  // const MOPNToken = await ethers.getContractFactory("MOPNToken");
  // const mt = await MOPNToken.deploy();
  // console.log("https://goerli.etherscan.io/tx/" + mt.deployTransaction.hash);
  // await mt.deployed();
  const mt = await ethers.getContractAt("MOPNToken", "0x802aea0a0A3178f6d6692b65004f143be5368a90");
  console.log("MOPNToken", mt.address);

  console.log("deploy Governance...");
  // const Governance = await ethers.getContractFactory("Governance");
  // const governance = await Governance.deploy(0);
  // console.log("https://goerli.etherscan.io/tx/" + governance.deployTransaction.hash);
  // await governance.deployed();
  const governance = await ethers.getContractAt(
    "Governance",
    "0xb864e6Bf6328c05bed3B94b17416A075d356271d"
  );
  console.log("Governance", governance.address);

  console.log("deploy Map...");
  // const Map = await ethers.getContractFactory("Map", {
  //   libraries: {
  //     TileMath: tileMath.address,
  //   },
  // });
  // const map = await Map.deploy();
  // console.log("https://goerli.etherscan.io/tx/" + map.deployTransaction.hash);
  // await map.deployed();
  const map = await ethers.getContractAt("Map", "0x4CB7fEcb203f3AD11357c368dF16c05D92fB2EA2");
  console.log("Map", map.address);

  console.log("deploy NFTSVG...");
  // const NFTSVG = await ethers.getContractFactory("NFTSVG");
  // const nftsvg = await NFTSVG.deploy();
  // console.log("https://goerli.etherscan.io/tx/" + nftsvg.deployTransaction.hash);
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
  // console.log("https://goerli.etherscan.io/tx/" + nftmetadata.deployTransaction.hash);
  // await nftmetadata.deployed();
  const nftmetadata = await ethers.getContractAt(
    "NFTMetaData",
    "0x3EE256Eeef106798ED679a17A38d475840213Fac"
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
  // console.log("https://goerli.etherscan.io/tx/" + render.deployTransaction.hash);
  // await render.deployed();
  const render = await ethers.getContractAt(
    "LandMetaDataRender",
    "0x4d8C79EC0BA420bEC22c88c22e74591bB279D4C2"
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
  // console.log("https://goerli.etherscan.io/tx/" + land.deployTransaction.hash);
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
    "0xb33a329679e005CFD50Af2f477d30800F8ff05E7"
  );
  console.log("TESTNFT", testnft.address);

  // console.log("transfer MOPNToken owner...");
  // const energytransownertx = await mt.transferOwnership(governance.address);
  // await energytransownertx.wait();
  // console.log("done");

  // console.log("transfer Bomb owner...");
  // const bombtransownertx = await bomb.transferOwnership(governance.address);
  // await bombtransownertx.wait();
  // console.log("done");

  console.log("Governance update MOPN Contracts");
  const governancesetmopntx = await governance.updateMOPNContracts(
    auctionHouse.address,
    avatar.address,
    bomb.address,
    mt.address,
    map.address,
    //"0x0B265c1010367647Ea0F2e87563c24948f13bcb2"
    land.address
  );
  await governancesetmopntx.wait();
  console.log("done");

  // console.log("AuctionHouse update Governance Contract");
  // const arsenalsetgovernancecontracttx = await auctionHouse.setGovernanceContract(
  //   governance.address
  // );
  // await arsenalsetgovernancecontracttx.wait();
  // console.log("done");

  // console.log("Avatar update Governance Contract");
  // const avatarsetgovernancecontracttx = await avatar.setGovernanceContract(governance.address);
  // await avatarsetgovernancecontracttx.wait();
  // console.log("done");

  // console.log("Map update Governance Contract");
  // const mapsetgovernancecontracttx = await map.setGovernanceContract(governance.address);
  // await mapsetgovernancecontracttx.wait();
  // console.log("done");

  // console.log("Land Render update Governance Contract");
  // const rendersetgovernancecontracttx = await render.setGovernanceContract(governance.address);
  // await rendersetgovernancecontracttx.wait();
  // console.log("done");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
