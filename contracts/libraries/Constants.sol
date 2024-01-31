// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

library Constants {
    uint256 public constant MTReduceInterval = 604800;
    uint256 public constant MaxCollectionOnMapNum = 10000;

    uint8 internal constant NOT_ENTERED = 1;
    uint8 internal constant ENTERED = 2;
}
