const MOPNContract = require("./MOPNContract");
const TheGraph = require("../simulator/TheGraph");

async function main() {
  // MOPNContract.setCurrentAccount(1);
  // console.log(await MOPNContract.moveTo("0x34a08ac41031d82c8f47c83705913bccca18465b", 1, 10300980));
  // console.log(await MOPNContract.buybomb(1));
  // console.log(await MOPNContract.stackMT('0x34a08ac41031d82c8f47c83705913bccca18465b', 1000000000));
  // console.log(await MOPNContract.removeStakingMT('0x34a08ac41031d82c8f47c83705913bccca18465b', "1000000000000000000000"));
  // const accounts = [
  //   "0xc6a3d78d7f2ddcb807dcb0c76a1b2145fa88c956",
  //   "0x315d5d65b95150efb88687055cdcd4dc310d13be",
  //   "0x3e2299d35e1caaf6aed27c7853ec6df80d022bad",
  // ];
  // for (const account of accounts) {
  //   console.log(await MOPNContract.getAccountNFTInfo(account));
  // }

  console.log(MOPNMath.LandRingNum(7));

  await MOPNContract.mintMockNFTs("0x1fE6879DCDdfC5b1c1Fa19bf42FD3D85fFF282e4", 5);
}

async function getCollectionOnMapData(collection) {
  const centerCoordinate = {
    "0xD7ea10E5D7CA72AF25b6502A7919d0cDBBC16A3E": 10001000,
  };

  const accounts = await TheGraph.getCollectionOnMapAccounts(collection);
  const coordinates = [];
  const tokenIds = [];
  for (const account of accounts) {
    coordinates.push(account.coordinate);
    tokenIds.push(account.tokenId);
  }
  return {
    center: centerCoordinate[collection],
    coordinates: coordinates,
    tokenIds: tokenIds,
  };
}

async function getCollectionNextMoveGrid(collection) {
  [center, coodinates, tokenIds] = await getCollectionOnMapData(collection);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
