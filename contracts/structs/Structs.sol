// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error BlockCoordinateError();

struct Block {
    int16 x;
    int16 y;
    int16 z;
}

struct AvatarData {
    uint64 blockCoordinatInt;
    uint256 COID;
    uint256 tokenId;
    uint256 BLER;
    uint256 BLERLastCalTime;
    uint256 BLERTank;
}

struct CollectionData {
    bytes6 color;
}

struct NFToken {
    address collectionContract;
    uint256 tokenId;
}
