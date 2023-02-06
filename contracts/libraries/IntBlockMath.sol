// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../structs/Structs.sol";

library IntBlockMath {
    using IntBlockMath for uint64;

    function check(uint64 blockCoordinate) public pure {
        uint64[3] memory coodinateArr = coordinateIntToArr(blockCoordinate);
        if (coodinateArr[0] + coodinateArr[1] + coodinateArr[2] != 3000) {
            revert BlockCoordinateError();
        }
    }

    function getBlockBEPS(
        uint64 blockCoordinate
    ) public pure returns (uint256) {
        uint64[3] memory coordinateArr = coordinateIntToArr(blockCoordinate);
        if (coordinateArr[0] % 10 == 0) {
            if (coordinateArr[1] % 10 == 0) {
                return 15;
            }
            return 5;
        }
        return 1;
    }

    function getPassType(
        uint64 PassId
    ) public pure returns (uint256 _passType) {
        uint64 ringNum = PassRingNum(PassId);
        if (ringNum <= 6) {
            _passType = 2;
        } else if (ringNum >= 30 && ringNum <= 34) {
            _passType = 1;
        }
    }

    function PassRingNum(uint64 PassId) public pure returns (uint64 n) {
        n = uint16((Math.sqrt(9 + 12 * (uint256(PassId) - 1)) - 3) / (6));
        if ((3 * n * n + 3 * n + 1) == PassId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function PassRingPos(uint64 PassId) public pure returns (uint64) {
        uint64 ringNum = PassRingNum(PassId) - 1;
        return PassId - (3 * ringNum * ringNum + 3 * ringNum + 1);
    }

    function PassRingStartCenterBlock(
        uint64 PassIdRingNum_
    ) public pure returns (uint64) {
        return
            (1000 - PassIdRingNum_ * 5) *
            100000000 +
            (1000 + PassIdRingNum_ * 11) *
            10000 +
            (1000 - PassIdRingNum_ * 6);
    }

    function PassCenterBlock(
        uint64 PassId
    ) public pure returns (uint64 blockCoordinate) {
        if (PassId == 1) {
            return 100010001000;
        }

        uint64 PassIdRingNum_ = PassRingNum(PassId);
        uint64[3] memory startblock = coordinateIntToArr(
            PassRingStartCenterBlock(PassIdRingNum_)
        );
        uint64 PassIdRingPos_ = PassRingPos(PassId);
        uint64 side = uint64(Math.ceilDiv(PassIdRingPos_, PassIdRingNum_));
        uint64 sidepos = 0;
        if (PassIdRingNum_ > 1) {
            sidepos = (PassIdRingPos_ - 1) % PassIdRingNum_;
        }
        if (side == 1) {
            blockCoordinate = (startblock[0] + sidepos * 11) * 100000000;
            blockCoordinate += (startblock[1] - sidepos * 6) * 10000;
            blockCoordinate += startblock[2] - sidepos * 5;
        } else if (side == 2) {
            blockCoordinate = (2000 - startblock[2] + sidepos * 5) * 100000000;
            blockCoordinate += (2000 - startblock[0] - sidepos * 11) * 10000;
            blockCoordinate += 1000 - startblock[1] + sidepos * 6;
        } else if (side == 3) {
            blockCoordinate = (startblock[1] - sidepos * 6) * 100000000;
            blockCoordinate += (startblock[2] - sidepos * 5) * 10000;
            blockCoordinate += startblock[0] + sidepos * 11;
        } else if (side == 4) {
            blockCoordinate = (2000 - startblock[0] - sidepos * 11) * 100000000;
            blockCoordinate += (1000 - startblock[1] + sidepos * 6) * 10000;
            blockCoordinate += 2000 - startblock[2] + sidepos * 5;
        } else if (side == 5) {
            blockCoordinate = (startblock[2] - sidepos * 5) * 100000000;
            blockCoordinate += (startblock[0] + sidepos * 11) * 10000;
            blockCoordinate += startblock[1] - sidepos * 6;
        } else if (side == 6) {
            blockCoordinate = (1000 - startblock[1] + sidepos * 6) * 100000000;
            blockCoordinate += (2000 - startblock[2] + sidepos * 5) * 10000;
            blockCoordinate += 2000 - startblock[0] - sidepos * 11;
        }
    }

    function coordinateIntToArr(
        uint64 blockCoordinate
    ) public pure returns (uint64[3] memory coordinateArr) {
        coordinateArr[0] = blockCoordinate / 100000000;
        coordinateArr[1] = (blockCoordinate % 100000000) / 10000;
        coordinateArr[2] = blockCoordinate % 10000;
    }

    function blockSpiralRingBlocks(
        uint64 blockcoordinate,
        uint256 radius
    ) public pure returns (uint64[] memory) {
        uint256 blockNum = 3 * radius * radius + 3 * radius;
        uint64[] memory blocks = new uint64[](blockNum);
        blocks[0] = blockcoordinate;
        for (uint256 i = 1; i <= radius; i++) {
            uint64 startBlock = blockcoordinate + uint64(9999 * i);
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    blocks[(i - 1) * 6 + j * i + k + 1] = startBlock;
                    startBlock = neighbor(startBlock, j);
                }
            }
        }
        return blocks;
    }

    function blockRingBlocks(
        uint64 blockcoordinate,
        uint256 radius
    ) public pure returns (uint64[] memory) {
        uint256 blockNum = 6 * radius;
        uint64[] memory blocks = new uint64[](blockNum);
        uint64 startBlock = blockcoordinate + uint64(9999 * radius);
        blocks[0] = blockcoordinate;
        for (uint256 j = 0; j < 6; j++) {
            for (uint256 k = 0; k < radius; k++) {
                blocks[j * radius + k + 1] = startBlock;
                startBlock = neighbor(startBlock, j);
            }
        }
        return blocks;
    }

    function blockSpheres(
        uint64 blockcoordinate
    ) public pure returns (uint64[] memory) {
        uint64[] memory blocks = new uint64[](7);
        uint64 startBlock = blockcoordinate + uint64(9999);
        blocks[0] = blockcoordinate;
        for (uint256 i = 1; i < 7; i++) {
            blocks[i] = startBlock;
            startBlock = neighbor(startBlock, i);
        }
        return blocks;
    }

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
        } else if (direction_ == 5) {
            return 99999999;
        } else {
            return 0;
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
