const centerTiles = require("./LandCenterTiles.json");

function LandRingNum(LandId) {
  let n = Math.floor((Math.sqrt(9 + 12 * (LandId - 1)) - 3) / 6);
  if (3 * n * n + 3 * n + 1 == LandId) {
    return n;
  } else {
    return n + 1;
  }
}

function LandRingPos(LandId) {
  const ringNum = LandRingNum(LandId) - 1;
  return LandId - (3 * ringNum * ringNum + 3 * ringNum + 1);
}

function LandRingStartCenterTile(LandIdRingNum_) {
  return (1000 - LandIdRingNum_ * 5) * 10000 + (1000 + LandIdRingNum_ * 11);
}

function LandCenterTile(LandId) {
  if (LandId == 1) {
    return 10001000;
  }

  const LandIdRingNum_ = LandRingNum(LandId);

  const starttile = coordinateIntToArr(LandRingStartCenterTile(LandIdRingNum_));

  const LandIdRingPos_ = LandRingPos(LandId);

  const side = Math.ceil(LandIdRingPos_ / LandIdRingNum_);

  let sidepos = 0;
  if (LandIdRingNum_ > 1) {
    sidepos = (LandIdRingPos_ - 1) % LandIdRingNum_;
  }

  let tileCoordinate = 0;
  if (side == 1) {
    tileCoordinate = (starttile[0] + sidepos * 11) * 10000;
    tileCoordinate += starttile[1] - sidepos * 6;
  } else if (side == 2) {
    tileCoordinate = (2000 - starttile[2] + sidepos * 5) * 10000;
    tileCoordinate += 2000 - starttile[0] - sidepos * 11;
  } else if (side == 3) {
    tileCoordinate = (starttile[1] - sidepos * 6) * 10000;
    tileCoordinate += starttile[2] - sidepos * 5;
  } else if (side == 4) {
    tileCoordinate = (2000 - starttile[0] - sidepos * 11) * 10000;
    tileCoordinate += 2000 - starttile[1] + sidepos * 6;
  } else if (side == 5) {
    tileCoordinate = (starttile[2] - sidepos * 5) * 10000;
    tileCoordinate += starttile[0] + sidepos * 11;
  } else if (side == 6) {
    tileCoordinate = (2000 - starttile[1] + sidepos * 6) * 10000;
    tileCoordinate += 2000 - starttile[2] + sidepos * 5;
  }
  return tileCoordinate;
}

function coordinateIntToArr(tileCoordinate) {
  let coordinateArr = [];
  coordinateArr[0] = Math.floor(tileCoordinate / 10000);
  coordinateArr[1] = tileCoordinate % 10000;
  coordinateArr[2] = 3000 - (coordinateArr[0] + coordinateArr[1]);
  return coordinateArr;
}

function coordinateIntToXY(tileCoordinate) {
  return { x: Math.floor(tileCoordinate / 10000) - 1000, y: (tileCoordinate % 10000) - 1000 };
}

function coordinateXYToInt(coordinateXY) {
  return (1000 + coordinateXY.x) * 10000 + 1000 + coordinateXY.y;
}

function getLandTilesEAW(LandId) {
  let tileCoordinate = LandCenterTile(LandId);
  let TilesEAW = [];
  TilesEAW[0] = getTileEAW(tileCoordinate);
  for (let i = 1; i <= 5; i++) {
    tileCoordinate++;
    const preringtiles = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
    for (let j = 0; j < 6; j++) {
      for (let k = 0; k < i; k++) {
        TilesEAW[preringtiles + j * i + k + 1] = getTileEAW(tileCoordinate);
        tileCoordinate = neighbor(tileCoordinate, j);
      }
    }
  }
  return TilesEAW;
}

function getTileEAW(tileCoordinate) {
  if (Math.floor(tileCoordinate / 10000) % 10 == 0) {
    if (tileCoordinate % 10 == 0) {
      return 15;
    }
    return 5;
  } else if (tileCoordinate % 10 == 0) {
    return 5;
  }
  return 1;
}

function direction(direction_) {
  if (direction_ == 0) {
    return 9999;
  } else if (direction_ == 1) {
    return -1;
  } else if (direction_ == 2) {
    return -10000;
  } else if (direction_ == 3) {
    return -9999;
  } else if (direction_ == 4) {
    return 1;
  } else if (direction_ == 5) {
    return 10000;
  } else {
    return 0;
  }
}

function neighbor(tileCoordinate, direction_) {
  return tileCoordinate + direction(direction_);
}

function getTileLandId(tileCoordinate) {
  if (centerTiles[tileCoordinate] != undefined) return centerTiles[tileCoordinate];
  for (let i = 1; i <= 5; i++) {
    tileCoordinate++;
    for (let j = 0; j < 6; j++) {
      for (let k = 0; k < i; k++) {
        if (centerTiles[tileCoordinate] != undefined) return centerTiles[tileCoordinate];
        tileCoordinate = neighbor(tileCoordinate, j);
      }
    }
  }
  return 0;
}

function checkLandIdOpen(LandId, avatarNum) {
  let ringNum = LandRingNum(LandId);
  if (ringNum == 0) ringNum++;
  if (avatarNum < (ringNum - 1) * 100) {
    return false;
  }
  return true;
}

function COIDToColor(COID) {
  let h = 0,
    s = 0,
    l = 0;

  let i = 5,
    batch = 4096,
    k = 0,
    v = 0,
    step = 4096,
    ht = 0,
    st = 0,
    lt = 0;

  while (true) {
    if (COID < step) {
      COID = (COID % 40) * Math.floor(batch / 40) + Math.floor(COID / 40);
      k = 2 ** (i - 1);
      v = COID - (step - batch);
      ht = Math.floor(v / (k * k));
      h = Math.round((360 / k) * (ht + 0.5));
      v = v - ht * (k * k);
      st = Math.floor(v / k);
      s = 100 - Math.round((45 / k) * (st + 0.5));
      lt = v - st * k;
      l = 50 + Math.floor((30 / k) * (lt + 0.5));
      break;
    }
    batch = 8 ** i;
    step += batch;
    i++;
  }

  return `hsl(${h},${s}%,${l}%)`;
}

function getCoordinateMapDiff(startCoordinate, endCoordinate) {
  const xrange = 4;

  let width = endCoordinate.x - startCoordinate.x;
  let height;
  if (width > 0) {
    height = endCoordinate.y - (startCoordinate.y - Math.floor(width / 2));
  } else if (width < 0) {
    height = endCoordinate.y - (startCoordinate.y + Math.floor(Math.abs(width) / 2));
  } else {
    height = endCoordinate.y - startCoordinate.y;
  }

  console.log(width, height);

  let hexes = { add: [], remove: [] };

  if (width != 0 || height != 0) {
    if (width >= 0 && height >= 0) {
      hexes.add = getCoordinateByRange(
        { x: endCoordinate.x - xrange, y: endCoordinate.y + xrange },
        xrange * 2 + 1,
        height
      );

      hexes.add = hexes.add.concat(
        getCoordinateByRange(
          { x: startCoordinate.x + xrange, y: startCoordinate.y },
          width,
          xrange + 1 - height
        )
      );
      hexes.remove = getCoordinateByRange(
        { x: startCoordinate.x - xrange, y: startCoordinate.y + xrange },
        width,
        xrange + 1
      );
      hexes.remove = hexes.remove.concat(
        getCoordinateByRange(
          {
            x: endCoordinate.x - xrange,
            y: endCoordinate.y,
          },
          xrange * 2 + 1 - width,
          height
        )
      );
    } else if (width >= 0 && height < 0) {
      hexes.add = getCoordinateByRange(
        { x: startCoordinate.x + xrange, y: startCoordinate.y + height },
        width,
        xrange + 1
      );
      hexes.add = hexes.add.concat(
        getCoordinateByRange(
          { x: endCoordinate.x - xrange, y: endCoordinate.y - height },
          xrange + 1 - width,
          -height
        )
      );
      hexes.remove = getCoordinateByRange(
        {
          x: startCoordinate.x - xrange,
          y: startCoordinate.y + xrange,
        },
        xrange * 2 + 1,
        -height
      );
      hexes.remove = hexes.remove.concat(
        getCoordinateByRange(
          {
            x: startCoordinate.x - xrange,
            y: startCoordinate.y + xrange + height,
          },
          width,
          xrange + 1 + height
        )
      );
    } else if (width < 0 && height >= 0) {
      hexes.add = getCoordinateByRange(
        {
          x: endCoordinate.x - xrange,
          y: endCoordinate.y + xrange,
        },
        xrange * 2 + 1,
        height
      );
      hexes.add = hexes.add.concat(
        getCoordinateByRange({ x: endCoordinate.x - xrange, y: endCoordinate.y + xrange - height })
      );
      hexes.remove = getCoordinateByRange(
        {
          x: endCoordinate.x + xrange,
          y: endCoordinate.y - height,
        },
        -width,
        xrange + 1
      );
      hexes.remove = hexes.remove.concat(
        getCoordinateByRange(
          {
            x: startCoordinate.x - xrange,
            y: startCoordinate.y + height,
          },
          xrange * 2 + 1,
          height
        )
      );
    } else if (width < 0 && height < 0) {
      hexes.add = getCoordinateByRange(
        {
          x: endCoordinate.x - xrange,
          y: endCoordinate.y + xrange,
        },
        -width,
        xrange + 1
      );
      hexes.add = hexes.add.concat(
        getCoordinateByRange(
          { x: startCoordinate.x - xrange, y: startCoordinate.y },
          xrange * 2 + 1 + width,
          -height
        )
      );
      hexes.remove = getCoordinateByRange(
        {
          x: startCoordinate.x + xrange,
          y: startCoordinate.y - xrange,
        },
        xrange * 2 + 1,
        -height
      );
      hexes.remove = hexes.remove.concat(
        getCoordinateByRange(
          {
            x: endCoordinate.x + xrange,
            y: endCoordinate.y,
          },
          -width,
          xrange + 1 + height
        )
      );
    }
  }
  return hexes;
}

function getCoordinateByRange(startCoordinate, width, height) {
  let coordinates = [];
  let coordinate = startCoordinate;
  for (let i = 0; i < Math.abs(height); i++) {
    for (let j = 0; j < Math.abs(width); j++) {
      coordinates.push(coordinate);

      coordinate = coordinateIntToXY(
        width > 0
          ? neighbor(coordinateXYToInt(coordinate), j % 2 == 0 ? 5 : 0)
          : neighbor(coordinateXYToInt(coordinate), j % 2 == 0 ? 3 : 2)
      );
    }
    startCoordinate = coordinateIntToXY(
      neighbor(coordinateXYToInt(startCoordinate), height > 0 ? 1 : 4)
    );
    coordinate = startCoordinate;
  }
  return coordinates;
}

module.exports = {
  LandRingNum,
  LandRingPos,
  LandRingStartCenterTile,
  LandCenterTile,
  getTileEAW,
  getLandTilesEAW,
  neighbor,
  getTileLandId,
  checkLandIdOpen,
  coordinateIntToArr,
  coordinateIntToXY,
  coordinateXYToInt,
  COIDToColor,
  getCoordinateMapDiff,
};
