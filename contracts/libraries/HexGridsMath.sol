// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IntBlockMath.sol";
import "./BlockMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

error BlockIndexOverFlow();
error BlockNotInPass();
error RandomSeedInvalid();

bytes constant initBlockLevels = "678851ac687a239ab7ba923c49bcbb995c45accb6b508c4c6897a59cbcba98853ab3bca69c7c6878a967742b4a1";

library HexGridsMath {
    using BlockMath for Block;
    using IntBlockMath for uint64;

    function PassRingNum(uint16 PassId) public pure returns (uint16 n) {
        n = uint16((Math.sqrt(9 + 12 * (PassId - 1)) - 3) / (6));
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

    function PassBlockRange(
        Block memory centerBlock_
    ) public pure returns (int16[] memory, int16[] memory, int16[] memory) {
        int16[] memory xrange = new int16[](11);
        int16[] memory yrange = new int16[](11);
        int16[] memory zrange = new int16[](11);
        for (uint16 i = 1; i < 6; i++) {
            int16 i16 = int16(i);
            xrange[i * 2] = centerBlock_.x + i16;
            xrange[i * 2 - 1] = centerBlock_.x - i16;
            yrange[i * 2] = centerBlock_.y + i16;
            yrange[i * 2 - 1] = centerBlock_.y - i16;
            zrange[i * 2] = centerBlock_.z + i16;
            zrange[i * 2 - 1] = centerBlock_.z - i16;
        }
        xrange[0] = centerBlock_.x;
        yrange[0] = centerBlock_.y;
        zrange[0] = centerBlock_.z;
        return (xrange, yrange, zrange);
    }

    function blockIndex(
        Block memory block_,
        Block memory centerPointBlock
    ) public pure returns (uint256) {
        int16 dis = centerPointBlock.distance(block_);
        if (dis > 5) revert BlockNotInPass();
        dis--;
        int16 blockIndex_ = 3 * dis * dis + 3 * dis;
        dis++;
        block_ = block_.subtract(centerPointBlock);
        if (block_.x >= 0 && block_.y > 0 && block_.z < 0) {
            blockIndex_ += Block(0, dis, -dis).distance(block_) + 1;
        } else if (block_.x > 0 && block_.y <= 0 && block_.z < 0) {
            blockIndex_ += Block(dis, 0, -dis).distance(block_) + 1 + dis;
        } else if (block_.x > 0 && block_.y < 0 && block_.z >= 0) {
            blockIndex_ += Block(dis, -dis, 0).distance(block_) + 1 + dis * 2;
        } else if (block_.x <= 0 && block_.y < 0 && block_.z > 0) {
            blockIndex_ += Block(0, -dis, dis).distance(block_) + 1 + dis * 3;
        } else if (block_.x < 0 && block_.y >= 0 && block_.z > 0) {
            blockIndex_ += Block(-dis, 0, dis).distance(block_) + 1 + dis * 4;
        } else {
            blockIndex_ += Block(-dis, dis, 0).distance(block_) + 1 + dis * 5;
        }
        return uint256(int256(blockIndex_));
    }

    function blockLevels(
        bytes32 randomseed
    ) public pure returns (uint8[] memory) {
        if (randomseed.length < 10) {
            revert RandomSeedInvalid();
        }
        unchecked {
            uint8[] memory blockLevels_ = new uint8[](91);
            uint256 startIndex = uint256(uint8(randomseed[0])) % 91;
            uint256 k = 0;
            uint256 index;
            for (uint256 i = 0; i < 9; i++) {
                uint256 groupIndex = uint256(uint8(randomseed[i + 1])) % 10;

                for (uint256 j = 0; j < 10; j++) {
                    index =
                        (startIndex + (i * 10) + ((groupIndex + j) % 10)) %
                        91;
                    blockLevels_[k] = convertBytes1level(
                        initBlockLevels[index]
                    );
                    k++;
                }
            }
            if (startIndex == 0) {
                blockLevels_[k] = convertBytes1level(initBlockLevels[k]);
            } else {
                blockLevels_[k] = convertBytes1level(
                    initBlockLevels[startIndex - 1]
                );
            }
            return blockLevels_;
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
                    startBlock = startBlock.neighbor(j);
                }
            }
        }

        return blocks;
    }

    function blockSpiralRingBlockInts(
        uint64 blockcoordinate,
        uint256 radius
    ) public pure returns (uint64[] memory) {
        uint256 blockNum = 3 * radius * radius + 3 * radius;
        uint64[] memory blocks = new uint64[](blockNum);

        for (uint256 i = 1; i <= radius; i++) {
            uint64 startBlock = blockcoordinate + uint64(10000 * i - 1 * i);

            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    blocks[(i - 1) * 6 + j * i + k] = startBlock;
                    startBlock = startBlock.neighbor(j);
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
                startBlock = startBlock.neighbor(j);
            }
        }

        return blocks;
    }

    function blockRingBlockInts(
        uint64 blockcoordinate,
        uint256 radius
    ) public pure returns (uint64[] memory) {
        uint256 blockNum = 6 * radius;
        uint64[] memory blocks = new uint64[](blockNum);

        uint64 startBlock = blockcoordinate + uint64(9999 * radius);

        for (uint256 j = 0; j < 6; j++) {
            for (uint256 k = 0; k < radius; k++) {
                blocks[j * radius + k] = startBlock;
                startBlock = startBlock.neighbor(j);
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
            startBlock = startBlock.neighbor(i);
        }

        return blocks;
    }

    function blockIntSpheres(
        uint64 blockcoordinate
    ) public pure returns (uint64[] memory) {
        uint64[] memory blocks = new uint64[](6);

        uint64 startBlock = blockcoordinate + uint64(9999);

        for (uint256 i = 0; i < 6; i++) {
            blocks[i] = startBlock;
            startBlock = startBlock.neighbor(i);
        }

        return blocks;
    }

    function convertBytes1level(bytes1 level) public pure returns (uint8) {
        uint8 uint8level = uint8(level);
        if (uint8level < 97) {
            return uint8level - 48;
        } else {
            return uint8level - 87;
        }
    }
}
