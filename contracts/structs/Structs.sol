// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error BlockCoordinateError();
error linkBlockError();
error BlockHasEnemy();

struct AvatarData {
    uint32 blockCoordinate;
    uint256 COID;
    uint256 tokenId;
    uint256 BoomUsed;
}
