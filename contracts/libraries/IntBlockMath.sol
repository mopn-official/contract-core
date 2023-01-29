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

    function int16abs(int16 n) internal pure returns (int16) {
        unchecked {
            return n >= 0 ? n : -n;
        }
    }
}
