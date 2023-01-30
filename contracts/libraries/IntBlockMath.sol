// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "../structs/Structs.sol";

library IntBlockMath {
    function direction(uint256 direction_) public pure returns (int64) {
        if (direction_ == 0) {
            return 99990000;
        } else if (direction_ == 1) {
            return -9999;
        } else if (direction_ == 2) {
            return -99999999;
        } else if (direction_ == 3) {
            return -99990000;
        } else if (direction_ == 4) {
            return 9999;
        } else {
            return 99999999;
        }
    }

    function neighbor(
        uint64 blockcoordinate,
        uint256 direction_
    ) public pure returns (uint64) {
        return uint64(int64(blockcoordinate) + direction(direction_));
    }

    function fromBlock(Block memory block_) public pure returns (uint64 ckey) {
        unchecked {
            ckey = uint64(int64(1000 + block_.x)) * 100000000;
            ckey += uint64(int64(1000 + block_.y)) * 10000;
            ckey += uint64(int64(1000 + block_.z));
        }
    }

    function distance(uint64 a, uint64 b) public pure returns (uint64) {
        uint64 ax = a / 100000000;
        uint64 bx = b / 100000000;
        uint64 d = ax > bx ? ax - bx : bx - ax;
        ax = (a % 100000000) / 10000;
        bx = (b % 100000000) / 10000;
        d += ax > bx ? ax - bx : bx - ax;
        ax = a % 10000;
        bx = b % 10000;
        d += ax > bx ? ax - bx : bx - ax;
        return d / 2;
    }
}
