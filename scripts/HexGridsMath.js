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

  const startblock = coordinateIntToArr(PassRingStartCenterTile(PassIdRingNum_));

  const PassIdRingPos_ = PassRingPos(PassId);

  const side = Math.ceil(PassIdRingPos_ / PassIdRingNum_);

  let sidepos = 0;
  if (PassIdRingNum_ > 1) {
    sidepos = (PassIdRingPos_ - 1) % PassIdRingNum_;
  }

  let blockCoordinate = 0;
  if (side == 1) {
    blockCoordinate = (startblock[0] + sidepos * 11) * 10000;
    blockCoordinate += startblock[1] - sidepos * 6;
  } else if (side == 2) {
    blockCoordinate = (2000 - startblock[2] + sidepos * 5) * 10000;
    blockCoordinate += 2000 - startblock[0] - sidepos * 11;
  } else if (side == 3) {
    blockCoordinate = (startblock[1] - sidepos * 6) * 10000;
    blockCoordinate += startblock[2] - sidepos * 5;
  } else if (side == 4) {
    blockCoordinate = (2000 - startblock[0] - sidepos * 11) * 10000;
    blockCoordinate += 2000 - startblock[1] + sidepos * 6;
  } else if (side == 5) {
    blockCoordinate = (startblock[2] - sidepos * 5) * 10000;
    blockCoordinate += startblock[0] + sidepos * 11;
  } else if (side == 6) {
    blockCoordinate = (2000 - startblock[1] + sidepos * 6) * 10000;
    blockCoordinate += 2000 - startblock[2] + sidepos * 5;
  }
  return blockCoordinate;
}

function coordinateIntToArr(blockCoordinate) {
  let coordinateArr = [];
  coordinateArr[0] = Math.floor(blockCoordinate / 10000);
  coordinateArr[1] = blockCoordinate % 10000;
  coordinateArr[2] = 3000 - (coordinateArr[0] + coordinateArr[1]);
  return coordinateArr;
}

function getPassTilesEAW(PassId) {
  let blockCoordinate = PassCenterTile(PassId);
  let TilesEAW = [];
  TilesEAW[0] = getTileEAW(blockCoordinate);
  for (let i = 1; i <= 5; i++) {
    blockCoordinate++;
    const preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
    for (let j = 0; j < 6; j++) {
      for (let k = 0; k < i; k++) {
        TilesEAW[preringblocks + j * i + k + 1] = getTileEAW(blockCoordinate);
        blockCoordinate = neighbor(blockCoordinate, j);
      }
    }
  }
  return TilesEAW;
}

function getTileEAW(blockCoordinate) {
  if (Math.floor(blockCoordinate / 10000) % 10 == 0) {
    if (blockCoordinate % 10 == 0) {
      return 15;
    }
    return 5;
  } else if (blockCoordinate % 10 == 0) {
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

function neighbor(blockcoordinate, direction_) {
  return blockcoordinate + direction(direction_);
}

module.exports = {
  PassRingNum,
  PassRingPos,
  PassRingStartCenterTile,
  PassCenterTile,
  getTileEAW,
  getPassTilesEAW,
  neighbor,
};
