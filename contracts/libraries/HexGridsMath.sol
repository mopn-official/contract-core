// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BlockMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

error BlockIndexOverFlow();
error BlockNotInPass();
error RandomSeedInvalid();

bytes constant initBlockLevels = "678851ac687a239ab7ba923c49bcbb995c45accb6b508c4c6897a59cbcba98853ab3bca69c7c6878a967742b4a1";

library HexGridsMath {
    using BlockMath for Block;

    function PassRingNum(uint256 PassId) public pure returns (uint256 n) {
        n = (Math.sqrt(9 + 12 * (PassId - 1)) - 3) / (6);
        if ((3 * n * n + 3 * n + 1) == PassId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function PassRingPos(uint256 PassId) public pure returns (uint256) {
        uint256 ringNum = PassRingNum(PassId) - 1;
        return PassId - (3 * ringNum * ringNum + 3 * ringNum + 1);
    }

    function PassRingStartCenterBlock(
        uint256 PassIdRingNum_
    ) public pure returns (Block memory) {
        int16 PassIdRingNum__ = int16(uint16(PassIdRingNum_));
        return
            Block(
                -PassIdRingNum__ * 5,
                PassIdRingNum__ * 11,
                -PassIdRingNum__ * 6
            );
    }

    function PassCenterBlock(
        uint256 PassId
    ) public pure returns (Block memory block_) {
        if (PassId == 1) {
            return block_;
        }

        uint256 PassIdRingNum_ = PassRingNum(PassId);
        int256 PassIdRingNum__ = int256(PassIdRingNum_);
        Block memory startblock = PassRingStartCenterBlock(PassIdRingNum_);
        uint256 PassIdRingPos_ = PassRingPos(PassId);
        int256 PassIdRingPos__ = int256(PassIdRingPos_) - 1;

        uint256 side = Math.ceilDiv(PassIdRingPos_, PassIdRingNum_);
        int16 sidepos = 0;
        if (PassIdRingNum__ > 1) {
            sidepos = int16(PassIdRingPos__ % PassIdRingNum__);
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
        for (uint256 i = 1; i < 6; i++) {
            xrange[i * 2] = centerBlock_.x + int16(uint16(i));
            xrange[i * 2 - 1] = centerBlock_.x - int16(uint16(i));
            yrange[i * 2] = centerBlock_.y + int16(uint16(i));
            yrange[i * 2 - 1] = centerBlock_.y - int16(uint16(i));
            zrange[i * 2] = centerBlock_.z + int16(uint16(i));
            zrange[i * 2 - 1] = centerBlock_.z - int16(uint16(i));
        }
        xrange[0] = centerBlock_.x;
        yrange[0] = centerBlock_.y;
        zrange[0] = centerBlock_.z;
        return (xrange, yrange, zrange);
    }

    function blockIndex(
        Block memory block_,
        uint256 PassId
    ) public pure returns (int16 blockIndex_) {
        Block memory centerPointBlock = PassCenterBlock(PassId);
        int16 dis = centerPointBlock.distance(block_);
        if (dis > 5) revert BlockNotInPass();
        dis--;
        blockIndex_ = 3 * dis * dis + 3 * dis;
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
        bytes32 randomseed,
        uint256 blockIndex_
    ) public pure returns (uint8) {
        if (randomseed.length < 10) {
            revert RandomSeedInvalid();
        }
        if (blockIndex_ > 90) {
            revert BlockIndexOverFlow();
        }
        unchecked {
            uint256 startIndex = uint256(uint8(randomseed[0])) % 91;
            if (blockIndex_ == 90) {
                if (startIndex == 0) {
                    return convertBytes1level(initBlockLevels[blockIndex_]);
                }
                return convertBytes1level(initBlockLevels[startIndex - 1]);
            }
            uint256 i = blockIndex_ / 10;
            uint256 groupIndex = uint256(uint8(randomseed[i])) % 10;
            uint256 index = (startIndex +
                i *
                10 +
                ((groupIndex + (blockIndex_ % 10)) % 10)) % 91;
            return convertBytes1level(initBlockLevels[index]);
        }
    }

    function blockRingBlocks(
        Block memory block_,
        uint256[] memory ringNums
    ) public pure returns (Block[] memory) {
        uint256 blockNum;
        uint256 i;
        for (i = 0; i < ringNums.length; i++) {
            blockNum += ringNums[i] * 6;
        }
        Block[] memory blocks = new Block[](blockNum);

        for (i = 0; i < ringNums.length; i++) {
            Block memory startBlock = Block(
                block_.x,
                block_.y + int16(int256(ringNums[i])),
                block_.z - int16(int256(ringNums[i]))
            );

            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < ringNums[i]; k++) {
                    blocks[j * ringNums[i] + k] = startBlock;
                    startBlock = startBlock.neighbor(j);
                }
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

    function convertBytes1level(bytes1 level) public pure returns (uint8) {
        uint8 uint8level = uint8(level);
        if (uint8level < 97) {
            return uint8level - 48;
        } else {
            return uint8level - 87;
        }
    }
}
