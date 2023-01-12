// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Block {
    int16 x;
    int16 y;
    int16 z;
}

struct AvatarData {
    Block block_;
    uint256 COID;
    uint256 tokenId;
    uint256 HP;
    uint256 ATT;
    uint256 STA;
}

struct CollectionData {
    bytes6 color;
}

struct NFToken {
    address collectionContract;
    uint256 tokenId;
}
