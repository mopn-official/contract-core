// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../structs/Structs.sol";

library BlockMath {
    using BlockMath for Block;

    function getPassType(uint16 PassId) public pure returns (uint8 _passType) {
        uint16 ringNum = PassRingNum(PassId);
        if (ringNum <= 6) {
            _passType = 2;
        } else if (ringNum >= 30 && ringNum <= 34) {
            _passType = 1;
        }
    }

    function PassRingNum(uint16 PassId) public pure returns (uint16 n) {
        n = uint16((Math.sqrt(9 + 12 * (uint256(PassId) - 1)) - 3) / (6));
        if ((3 * n * n + 3 * n + 1) == PassId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function PassRingPos(uint16 PassId) public pure returns (uint16) {
        uint16 ringNum = PassRingNum(PassId) - 1;
        return PassId - (3 * ringNum * ringNum + 3 * ringNum + 1);
    }

    function PassRingStartCenterBlock(
        uint16 PassIdRingNum_
    ) public pure returns (Block memory) {
        int16 PassIdRingNum__ = int16(PassIdRingNum_);
        return
            Block(
                -PassIdRingNum__ * 5,
                PassIdRingNum__ * 11,
                -PassIdRingNum__ * 6
            );
    }

    function PassCenterBlock(
        uint16 PassId
    ) public pure returns (Block memory block_) {
        if (PassId == 1) {
            return block_;
        }

        uint16 PassIdRingNum_ = PassRingNum(PassId);
        int16 PassIdRingNum__ = int16(PassIdRingNum_);
        Block memory startblock = PassRingStartCenterBlock(PassIdRingNum_);
        uint16 PassIdRingPos_ = PassRingPos(PassId);
        int16 PassIdRingPos__ = int16(PassIdRingPos_) - 1;

        uint256 side = Math.ceilDiv(PassIdRingPos_, PassIdRingNum_);
        int16 sidepos = 0;
        if (PassIdRingNum__ > 1) {
            sidepos = PassIdRingPos__ % PassIdRingNum__;
        }

        if (side == 1) {
            block_.x = startblock.x + sidepos * 11;
            block_.y = startblock.y - sidepos * 6;
            block_.z = startblock.z - sidepos * 5;
        } else if (side == 2) {
            block_.x = -startblock.z + sidepos * 5;
            block_.y = -startblock.x - sidepos * 11;
            block_.z = -startblock.y + sidepos * 6;
        } else if (side == 3) {
            block_.x = startblock.y - sidepos * 6;
            block_.y = startblock.z - sidepos * 5;
            block_.z = startblock.x + sidepos * 11;
        } else if (side == 4) {
            block_.x = -startblock.x - sidepos * 11;
            block_.y = -startblock.y + sidepos * 6;
            block_.z = -startblock.z + sidepos * 5;
        } else if (side == 5) {
            block_.x = startblock.z - sidepos * 5;
            block_.y = startblock.x + sidepos * 11;
            block_.z = startblock.y - sidepos * 6;
        } else if (side == 6) {
            block_.x = -startblock.y + sidepos * 6;
            block_.y = -startblock.z + sidepos * 5;
            block_.z = -startblock.x - sidepos * 11;
        }
    }

    function blockLevel(
        uint256 passContract,
        uint64 blockCoordinate
    ) public pure returns (uint8) {
        uint256 blockCoordinate_ = uint256(blockCoordinate);
        blockCoordinate_ =
            (blockCoordinate_ / 100000000) *
            ((blockCoordinate_ % 100000000) / 10000) *
            (blockCoordinate_ % 10000);
        return uint8((passContract / (10 ** (blockCoordinate_ % 30))) % 12) + 1;
    }

    function blockSpiralRingBlocks(
        Block memory block_,
        uint256 radius
    ) public pure returns (Block[] memory) {
        uint256 blockNum = 3 * radius * radius + 3 * radius;
        Block[] memory blocks = new Block[](blockNum);

        for (uint256 i = 0; i < radius; i++) {
            Block memory startBlock = Block(
                block_.x,
                block_.y + int16(int256(i)),
                block_.z - int16(int256(i))
            );

            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    blocks[j * i + k] = startBlock;
                    startBlock = neighbor(startBlock, j);
                }
            }
        }

        return blocks;
    }

    function blockRingBlocks(
        Block memory block_,
        uint256 radius
    ) public pure returns (Block[] memory) {
        uint256 blockNum = 6 * radius;
        Block[] memory blocks = new Block[](blockNum);

        Block memory startBlock = Block(
            block_.x,
            block_.y + int16(int256(radius)),
            block_.z - int16(int256(radius))
        );

        for (uint256 j = 0; j < 6; j++) {
            for (uint256 k = 0; k < radius; k++) {
                blocks[j * radius + k] = startBlock;
                startBlock = neighbor(startBlock, j);
            }
        }

        return blocks;
    }

    function blockSpheres(
        Block memory block_
    ) public pure returns (Block[] memory) {
        Block[] memory blocks = new Block[](6);

        Block memory startBlock = Block(block_.x, block_.y + 1, block_.z - 1);

        for (uint256 i = 0; i < 6; i++) {
            blocks[i] = startBlock;
            startBlock = neighbor(startBlock, i);
        }

        return blocks;
    }

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
