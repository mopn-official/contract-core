// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../structs/Structs.sol";

library IntBlockMath {
    using IntBlockMath for uint32;

    function check(uint32 blockCoordinate) public pure {
        uint32[3] memory coodinateArr = coordinateIntToArr(blockCoordinate);
        if (coodinateArr[0] + coodinateArr[1] + coodinateArr[2] != 3000) {
            revert BlockCoordinateError();
        }
    }

    function PassRingNum(uint32 PassId) public pure returns (uint32 n) {
        n = uint32((Math.sqrt(9 + 12 * (uint256(PassId) - 1)) - 3) / (6));
        if ((3 * n * n + 3 * n + 1) == PassId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function PassRingPos(uint32 PassId) public pure returns (uint32) {
        uint32 ringNum = PassRingNum(PassId) - 1;
        return PassId - (3 * ringNum * ringNum + 3 * ringNum + 1);
    }

    function PassRingStartCenterBlock(
        uint32 PassIdRingNum_
    ) public pure returns (uint32) {
        return
            (1000 - PassIdRingNum_ * 5) * 10000 + (1000 + PassIdRingNum_ * 11);
    }

    function PassCenterBlock(
        uint32 PassId
    ) public pure returns (uint32 blockCoordinate) {
        if (PassId == 1) {
            return 10001000;
        }

        uint32 PassIdRingNum_ = PassRingNum(PassId);

        uint32[3] memory startblock = coordinateIntToArr(
            PassRingStartCenterBlock(PassIdRingNum_)
        );

        uint32 PassIdRingPos_ = PassRingPos(PassId);

        uint32 side = uint32(Math.ceilDiv(PassIdRingPos_, PassIdRingNum_));

        uint32 sidepos = 0;
        if (PassIdRingNum_ > 1) {
            sidepos = (PassIdRingPos_ - 1) % PassIdRingNum_;
        }
        if (side == 1) {
            blockCoordinate = (startblock[0] + sidepos * 11) * 10000;
            blockCoordinate += startblock[1] - sidepos * 6;
        } else if (side == 2) {
            blockCoordinate = (2000 - startblock[2] + sidepos * 5) * 10000;
            blockCoordinate += 2000 - startblock[0] - sidepos * 11;
        } else if (side == 3) {
            blockCoordinate = (startblock[1] - sidepos * 6) * 10000;
            blockCoordinate += startblock[2] - sidepos * 5;
        } else if (side == 4) {
            blockCoordinate = (2000 - startblock[0] - sidepos * 11) * 10000;
            blockCoordinate += 2000 - startblock[1] + sidepos * 6;
        } else if (side == 5) {
            blockCoordinate = (startblock[2] - sidepos * 5) * 10000;
            blockCoordinate += startblock[0] + sidepos * 11;
        } else if (side == 6) {
            blockCoordinate = (2000 - startblock[1] + sidepos * 6) * 10000;
            blockCoordinate += 2000 - startblock[2] + sidepos * 5;
        }
    }

    function getBlockBEPS(
        uint32 blockCoordinate
    ) public pure returns (uint256) {
        if ((blockCoordinate / 10000) % 10 == 0) {
            if (blockCoordinate % 10 == 0) {
                return 15;
            }
            return 5;
        } else if (blockCoordinate % 10 == 0) {
            return 5;
        }
        return 1;
    }

    function coordinateIntToArr(
        uint32 blockCoordinate
    ) public pure returns (uint32[3] memory coordinateArr) {
        coordinateArr[0] = blockCoordinate / 10000;
        coordinateArr[1] = blockCoordinate % 10000;
        coordinateArr[2] = 3000 - (coordinateArr[0] + coordinateArr[1]);
    }

    function blockSpiralRingBlocks(
        uint32 blockCoordinate,
        uint256 radius
    ) public pure returns (uint32[] memory) {
        uint256 blockNum = 3 * radius * radius + 3 * radius;
        uint32[] memory blocks = new uint32[](blockNum);
        blocks[0] = blockCoordinate;
        for (uint256 i = 1; i <= radius; i++) {
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            blockCoordinate++;
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    blocks[preringblocks + j * i + k + 1] = blockCoordinate;
                    blockCoordinate = neighbor(blockCoordinate, j);
                }
            }
        }
        return blocks;
    }

    function blockRingBlocks(
        uint32 blockCoordinate,
        uint256 radius
    ) public pure returns (uint32[] memory) {
        uint256 blockNum = 6 * radius;
        uint32[] memory blocks = new uint32[](blockNum);

        blocks[0] = blockCoordinate;
        blockCoordinate += uint32(radius);
        for (uint256 j = 0; j < 6; j++) {
            for (uint256 k = 0; k < radius; k++) {
                blocks[j * radius + k + 1] = blockCoordinate;
                blockCoordinate = neighbor(blockCoordinate, j);
            }
        }
        return blocks;
    }

    function blockSpheres(
        uint32 blockcoordinate
    ) public pure returns (uint32[] memory) {
        uint32[] memory blocks = new uint32[](7);
        blocks[0] = blockcoordinate;
        blockcoordinate++;
        for (uint256 i = 1; i < 7; i++) {
            blocks[i] = blockcoordinate;
            blockcoordinate = neighbor(blockcoordinate, i);
        }
        return blocks;
    }

    function direction(uint256 direction_) public pure returns (int32) {
        if (direction_ == 0) {
            return 9999;
        } else if (direction_ == 1) {
            return -1;
        } else if (direction_ == 2) {
            return -10000;
        } else if (direction_ == 3) {
            return -9999;
        } else if (direction_ == 4) {
            return 1;
        } else if (direction_ == 5) {
            return 10000;
        } else {
            return 0;
        }
    }

    function neighbor(
        uint32 blockcoordinate,
        uint256 direction_
    ) public pure returns (uint32) {
        return uint32(int32(blockcoordinate) + direction(direction_));
    }

    function distance(uint32 a, uint32 b) public pure returns (uint32 d) {
        uint32[3] memory aarr = coordinateIntToArr(a);
        uint32[3] memory barr = coordinateIntToArr(b);
        for (uint256 i = 0; i < 3; i++) {
            d += aarr[i] > barr[i] ? aarr[i] - barr[i] : barr[i] - aarr[i];
        }

        return d / 2;
    }
}
