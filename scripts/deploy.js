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
  const bomb = await ethers.getContractAt("Bomb", "0x7da9b6eBa747D003b96A6333d7d66AdD53Bc5914");
  console.log("Bomb", bomb.address);

  console.log("deploy MOPNToken...");
  // const MOPNToken = await ethers.getContractFactory("MOPNToken");
  // const mt = await MOPNToken.deploy();
  // console.log("https://goerli.etherscan.io/tx/" + mt.deployTransaction.hash);
  // await mt.deployed();
  const mt = await ethers.getContractAt("MOPNToken", "0x3f120eCED583eE4FD8749a97C372E0eD75C42e03");
  console.log("MOPNToken", mt.address);

  console.log("deploy Governance...");
  // const Governance = await ethers.getContractFactory("Governance");
  // const governance = await Governance.deploy(0);
  // console.log("https://goerli.etherscan.io/tx/" + governance.deployTransaction.hash);
  // await governance.deployed();
  const governance = await ethers.getContractAt(
    "Governance",
    "0x928C618E6dFc51163a76D22218F7F1f01aEE7667"
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
    "0x99b858C3f57593ba9405eF8c390c588058661e8E"
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
  //   "0x6a77e7c1b144EAd03E2f4e240dBB0e723466D6Ef"
  // );
  // console.log("LandMetaDataRenderSolo:", render.address);

  console.log("deploy MOPNLand...");
  // const MOPNLand = await ethers.getContractFactory("MOPNLand");
  // const land = await MOPNLand.deploy();
  // console.log("https://goerli.etherscan.io/tx/" + land.deployTransaction.hash);
  // await land.deployed();
  const land = await ethers.getContractAt("MOPNLand", "0x86ce13c583872090d041cbD249dEbb2Eec105cc2");
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
  const arsenalsetgovernancecontracttx = await auctionHouse.setGovernanceContract(
    governance.address
  );
  await arsenalsetgovernancecontracttx.wait();
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
