const MOPNContract = require("./MOPNContract");
const TheGraph = require("./TheGraph");
const MOPNMath = require("../simulator/MOPNMath");
const { ZeroAddress } = require("ethers");

const centerCoordinate = {
  "0x46047f9d95eeb28aabb6017e1d6eb3abc8fdb611": { coordinate: "9901040", placeStyle: 2 },
  "0xaf5728834640c90accb2e082372ee40366559694": { coordinate: "10201000", placeStyle: 1 },
};

async function main() {
  const currentLandId = await MOPNContract.getCurrentLandId();
  console.log("currentLandId", currentLandId.toString());

  MOPNContract.setCurrentAccount(2);
  const collection = "0xaf5728834640c90accb2e082372ee40366559694";
  const collectionOnMapData = await getCollectionOnMapData(collection);

  const nextMoveTiles = await getCollectionNextMoveBatchData(collection, 2500);
  let tokenId = 0;

  for (const nextMoveTile of nextMoveTiles) {
    if (nextMoveTile.account != ZeroAddress) {
      console.log(nextMoveTile.coordinate, "jump 1");
      continue;
    }
    const xy = MOPNMath.coordinateIntToXY(nextMoveTile.coordinate);
    if (centerCoordinate[collection].placeStyle == 2) {
      if (xy.x % 10 != 0 && xy.y % 10 != 0) {
        console.log(nextMoveTile.coordinate, "jump 2");
        continue;
      }
    } else {
      if (xy.x % 2 != 0 || xy.y % 2 != 0) {
        console.log(nextMoveTile.coordinate, "jump 3");
        continue;
      }
    }

    const landId = MOPNMath.getTileLandId(nextMoveTile.coordinate);
    if (landId > currentLandId) {
      console.log(nextMoveTile.coordinate, "jump 4");
      continue;
    }

    const tileAccounts = await TheGraph.getMoveToTilesAccountsRich(nextMoveTile.coordinate);
    if ((await checkMoveToTile(collection, tileAccounts)) == false) {
      console.log(nextMoveTile.coordinate, "jump 5");
      continue;
    }

    while (true) {
      if (!collectionOnMapData.tokenIds.includes(tokenId.toString())) {
        break;
      }
      tokenId++;
    }

    console.log("move", collection, tokenId, "to", nextMoveTile.coordinate);
    collectionOnMapData.tokenIds.push(tokenId.toString());
    try {
      await MOPNContract.moveToRich(
        collection,
        tokenId,
        nextMoveTile.coordinate,
        landId,
        array_column(tileAccounts, "account")
      );
    } catch (error) {
      console.log(error.message);
    }
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

  let IndexRingNum = MOPNMath.HexagonIndexRingNum(startIndex);
  const IndexRingPos = MOPNMath.HexagonIndexRingPos(startIndex);
  const side = Math.ceil(IndexRingPos / IndexRingNum);

  let sidepos = 0;
  if (IndexRingNum > 1) {
    sidepos = (IndexRingPos - 1) % IndexRingNum;
  }

  let batchcoordinates = [];

  if (startIndex == 1) {
    batchcoordinates.push(centerCoordinate[collection].coordinate);
  }
  let coordinate =
    parseInt(centerCoordinate[collection].coordinate) +
    MOPNMath.direction(side < 3 ? side + 3 : side - 3) * IndexRingNum +
    MOPNMath.direction(side - 1) * sidepos;

  console.log(
    "center coordinate",
    centerCoordinate[collection].coordinate,
    "begin with ring num",
    IndexRingNum,
    "ring pos",
    IndexRingPos,
    "side",
    side,
    "sidepos",
    sidepos,
    "coordinate",
    coordinate.toString()
  );

  let batchnum = 0;
  let firstRing = true;
  while (batchnum < 500) {
    for (let j = 0; j < 6; j++) {
      if (firstRing && j < side - 1) continue;
      for (let k = 0; k < IndexRingNum; k++) {
        if (firstRing && k < sidepos) continue;
        if (batchnum > 500) break;
        batchcoordinates.push(coordinate.toString());
        coordinate = MOPNMath.neighbor(coordinate, j);
        batchnum++;
      }
    }
    coordinate = MOPNMath.neighbor(coordinate, 4);
    IndexRingNum++;
    firstRing = false;
  }

  return TheGraph.getTilesAccountsRich(batchcoordinates);
}

async function checkMoveToTile(collection, tileAccounts) {
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

function array_column(a, i, ok) {
  return a.length
    ? typeof ok === "undefined"
      ? [a[0][i], ...array_column(a.slice(1), i, ok)]
      : { [a[0][ok]]: i === null ? a[0] : a[0][i], ...array_column(a.slice(1), i, ok) }
    : [];
}
