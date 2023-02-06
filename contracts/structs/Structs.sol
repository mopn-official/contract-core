// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error BlockCoordinateError();
error linkBlockError();
error BlockHasEnemy();

struct Block {
    int16 x;
    int16 y;
    int16 z;
}

struct AvatarData {
    uint64 blockCoordinate;
    uint256 COID;
    uint256 tokenId;
    uint256 BoomUsed;
}
