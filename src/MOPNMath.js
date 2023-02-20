const centerTiles = require("./passCenterTiles.json");

function PassRingNum(PassId) {
  let n = Math.floor((Math.sqrt(9 + 12 * (PassId - 1)) - 3) / 6);
  if (3 * n * n + 3 * n + 1 == PassId) {
    return n;
  } else {
    return n + 1;
  }
}

function PassRingPos(PassId) {
  const ringNum = PassRingNum(PassId) - 1;
  return PassId - (3 * ringNum * ringNum + 3 * ringNum + 1);
}

function PassRingStartCenterTile(PassIdRingNum_) {
  return (1000 - PassIdRingNum_ * 5) * 10000 + (1000 + PassIdRingNum_ * 11);
}

function PassCenterTile(PassId) {
  if (PassId == 1) {
    return 10001000;
  }

  const PassIdRingNum_ = PassRingNum(PassId);

  const starttile = coordinateIntToArr(PassRingStartCenterTile(PassIdRingNum_));

  const PassIdRingPos_ = PassRingPos(PassId);

  const side = Math.ceil(PassIdRingPos_ / PassIdRingNum_);

  let sidepos = 0;
  if (PassIdRingNum_ > 1) {
    sidepos = (PassIdRingPos_ - 1) % PassIdRingNum_;
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

function getPassTilesEAW(PassId) {
  let tileCoordinate = PassCenterTile(PassId);
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

function getTilePassId(tileCoordinate) {
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

function checkPassIdOpen(PassId, avatarNum) {
  let ringNum = PassRingNum(PassId);
  if (ringNum == 0) ringNum++;
  if (avatarNum < (ringNum - 1) * 100) {
    return false;
  }
  return true;
}

function COIDToColor(COID) {
  COID--;
  const biground = Math.floor(COID / 10800) + 1;
  const hround = Math.floor((COID % 10800) / 360);
  const stimes = Math.floor((COID % 360) / 12) + 1;
  const hslot = COID % 12;

  const h = hslot * 30 + stimes;
  const s = 100 - hround * 3;

  const l = biground % 2 == 1 ? 50 + Math.floor(biground / 2) : 50 - Math.floor(biground / 2);

  return hslToHex(h, s, l);
}

function hslToHex(h, s, l) {
  l /= 100;
  const a = (s * Math.min(l, 1 - l)) / 100;
  const f = (n) => {
    const k = (n + h / 30) % 12;
    const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
    return Math.round(255 * color)
      .toString(16)
      .padStart(2, "0"); // convert to Hex and prefix "0" if needed
  };
  return `#${f(0)}${f(8)}${f(4)}`;
}

module.exports = {
  PassRingNum,
  PassRingPos,
  PassRingStartCenterTile,
  PassCenterTile,
  getTileEAW,
  getPassTilesEAW,
  neighbor,
  getTilePassId,
  checkPassIdOpen,
  coordinateIntToArr,
  coordinateIntToXY,
  coordinateXYToInt,
  COIDToColor,
};
