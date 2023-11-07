const MOPNContract = require("./MOPNContract");
const TheGraph = require("./TheGraph");
const MOPNMath = require("../simulator/MOPNMath");
const { ZeroAddress } = require("ethers");

const centerCoordinate = {
  "0x90ccfad2c1dc253285e379a0050a503d1a5abcee": { coordinate: 10001000, placeStyle: 1 },
};

async function main() {
  const collection = "0x90ccfad2c1dc253285e379a0050a503d1a5abcee";
  const collectionOnMapData = await getCollectionOnMapData(collection);

  console.log(collectionOnMapData);

  const nextMoveTiles = await getCollectionNextMoveBatchData(collection, 1);
  let tokenId = 0;

  for (const nextMoveTile of nextMoveTiles) {
    if (nextMoveTile.account != ZeroAddress) continue;
    const xy = MOPNMath.coordinateIntToXY(nextMoveTile.coordinate);
    if (xy.x % 2 != 0 || xy.y % 2 != 0) continue;
    if (centerCoordinate[collection].placeStyle == 2) {
      if (xy.x % 10 != 0 && xy.y % 10 != 0) continue;
    }
    if ((await checkMoveToTile(nextMoveTile.coordinate, collection)) == false) continue;

    console.log(nextMoveTile);
    while (true) {
      if (!collectionOnMapData.tokenIds.includes(tokenId.toString())) {
        break;
      }
      tokenId++;
    }

    console.log("move", collection, tokenId, "to", nextMoveTile.coordinate);
    collectionOnMapData.tokenIds.push(tokenId.toString());
    // await MOPNContract.moveTo(collection, tokenId, nextMoveTile.coordinate);
  }
}

async function getCollectionOnMapData(collection) {
  const accounts = await TheGraph.getCollectionOnMapAccounts(collection);
  const coordinates = [];
  const tokenIds = [];
  for (const account of accounts) {
    coordinates.push(account.coordinate);
    tokenIds.push(account.tokenId);
  }
  return {
    center: centerCoordinate[collection].coordinate,
    placeStyle: centerCoordinate[collection].placeStyle,
    coordinates: coordinates,
    tokenIds: tokenIds,
  };
}

async function getCollectionNextMoveBatchData(collection, startIndex) {
  if (!startIndex) startIndex = 1;
  const data = await getCollectionOnMapData(collection);

  let IndexRingNum = MOPNMath.HexagonIndexRingNum(startIndex);
  const IndexRingPos = MOPNMath.HexagonIndexRingPos(startIndex);
  const side = Math.ceil(IndexRingPos / IndexRingNum);

  let sidepos = 0;
  if (IndexRingNum > 1) {
    sidepos = (IndexRingPos - 1) % IndexRingNum;
  }

  let coordinate =
    data.center +
    MOPNMath.direction(side < 3 ? side + 3 : side - 3) * IndexRingNum +
    MOPNMath.direction(side - 1) * sidepos;

  let batchcoordinates = [];

  let batchnum = 0;
  let firstRing = true;
  while (batchnum < 100) {
    for (let j = 0; j < 6; j++) {
      if (firstRing && j < side - 1) continue;
      for (let k = 0; k < IndexRingNum; k++) {
        if (firstRing && k < sidepos) continue;
        batchcoordinates.push(coordinate.toString());
        coordinate = MOPNMath.neighbor(coordinate, j);
        batchnum++;
      }
    }
    coordinate = MOPNMath.neighbor(coordinate, 4);
    IndexRingNum++;
    firstRing = false;
  }

  console.log(batchcoordinates);
  return TheGraph.getTilesAccountsRich(batchcoordinates);
}

async function checkMoveToTile(coordinate, collection) {
  const tileAccounts = await TheGraph.getMoveToTilesAccountsRich(coordinate);
  for (let tileAccount of tileAccounts) {
    if (tileAccount.collection != ZeroAddress && tileAccount.collection != collection) {
      return false;
    }
  }
  return true;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
