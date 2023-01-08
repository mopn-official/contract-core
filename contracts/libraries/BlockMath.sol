// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "../structs/Structs.sol";

error BlockCoordinateError();

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

    // function coordinateBytes(Block memory block_) public pure returns (bytes9) {
    //     bytes memory serializedMessage = new bytes(9);

    //     uint256 x = uint256(int256(int16abs(block_.x)));
    //     uint256 y = uint256(int256(int16abs(block_.y)));
    //     uint256 z = uint256(int256(int16abs(block_.z)));

    //     serializedMessage[0] = block_.x >= 0 ? bytes1(uint8(1)) : bytes1(0);
    //     serializedMessage[1] = bytes1(uint8(x / (2 ** 8)));
    //     serializedMessage[2] = bytes1(uint8(x));

    //     serializedMessage[3] = block_.y >= 0 ? bytes1(uint8(1)) : bytes1(0);
    //     serializedMessage[4] = bytes1(uint8(y / (2 ** 8)));
    //     serializedMessage[5] = bytes1(uint8(y));

    //     serializedMessage[6] = block_.z >= 0 ? bytes1(uint8(1)) : bytes1(0);
    //     serializedMessage[7] = bytes1(uint8(z / (2 ** 8)));
    //     serializedMessage[8] = bytes1(uint8(z));

    //     return bytes9(serializedMessage);
    // }

    // xxxxyyyyzzzz
    function coordinateBytes(
        Block memory block_
    ) public pure returns (uint256 ckey) {
        ckey = uint256(int256(int16abs(block_.x))) * 100000000;
        ckey = block_.x >= 0 ? ckey : ckey + 100000000000;

        ckey += uint256(int256(int16abs(block_.y))) * 10000;
        ckey = block_.y >= 0 ? ckey : ckey + 10000000;

        ckey += uint256(int256(int16abs(block_.z)));
        ckey = block_.z >= 0 ? ckey : ckey + 1000;
    }

    function int16abs(int16 n) internal pure returns (int16) {
        unchecked {
            return n >= 0 ? n : -n;
        }
    }
}
