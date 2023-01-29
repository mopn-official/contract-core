// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "../structs/Structs.sol";

library BlockMath {
    function check(Block memory a) public pure {
        if (a.x + a.y + a.z != 0 || (a.x == 0 && a.y == 0 && a.z == 0)) {
            revert BlockCoordinateError();
        }
    }

    function add(
        Block memory a,
        Block memory b
    ) public pure returns (Block memory) {
        return Block(a.x + b.x, a.y + b.y, a.z + b.z);
    }

    function subtract(
        Block memory a,
        Block memory b
    ) public pure returns (Block memory) {
        return Block(a.x - b.x, a.y - b.y, a.z - b.z);
    }

    function length(Block memory a) public pure returns (int16) {
        return (int16abs(a.x) + int16abs(a.y) + int16abs(a.z)) / 2;
    }

    function distance(
        Block memory a,
        Block memory b
    ) public pure returns (int16) {
        return length(subtract(a, b));
    }

    function equals(Block memory a, Block memory b) public pure returns (bool) {
        return a.x == b.x && a.y == b.y && a.z == b.z;
    }

    function direction(uint256 direction_) public pure returns (Block memory) {
        if (direction_ == 0) {
            return Block(1, -1, 0);
        } else if (direction_ == 1) {
            return Block(0, -1, 1);
        } else if (direction_ == 2) {
            return Block(-1, 0, 1);
        } else if (direction_ == 3) {
            return Block(-1, 1, 0);
        } else if (direction_ == 4) {
            return Block(0, 1, -1);
        } else {
            return Block(1, 0, -1);
        }
    }

    function neighbor(
        Block memory block_,
        uint256 direction_
    ) public pure returns (Block memory) {
        return add(block_, direction(direction_));
    }

    function coordinateInt(
        Block memory block_
    ) public pure returns (uint64 ckey) {
        unchecked {
            ckey = uint64(int64(1000 + block_.x)) * 100000000;
            ckey += uint64(int64(1000 + block_.y)) * 10000;
            ckey += uint64(int64(1000 + block_.z));
        }
    }

    function fromCoordinateInt(
        uint64 coordinateInt_
    ) public pure returns (Block memory block_) {
        if (coordinateInt_ == 0) {
            coordinateInt_ = 100010001000;
        }
        int64 coordinateInt__ = int64(coordinateInt_);

        int16 xdata = int16(coordinateInt__ / 100000000);
        if (xdata >= 1000) block_.x = xdata - 1000;
        else block_.x = -(1000 - xdata);

        int16 ydata = int16((coordinateInt__ % 100000000) / 10000);
        if (ydata >= 1000) block_.y = ydata - 1000;
        else block_.y = -(1000 - ydata);

        int16 zdata = int16(coordinateInt__ % 10000);
        if (zdata >= 1000) block_.z = zdata - 1000;
        else block_.z = -(1000 - zdata);
    }

    function int16abs(int16 n) internal pure returns (int16) {
        unchecked {
            return n >= 0 ? n : -n;
        }
    }
}
