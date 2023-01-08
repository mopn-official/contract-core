// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPN.sol";
import "./libraries/HexGridsMath.sol";

contract Map {
    using BlockMath for Block;
    // Block => avatarId
    mapping(bytes9 => uint256) public blocks;

    IAvatar public Avatar;

    function setAvatarContract(address avatarContract_) public {
        Avatar = IAvatar(avatarContract_);
    }

    function avatarMove(
        Block memory blockFrom,
        Block memory blockTo
    ) public onlyAvatar {
        blocks[blockTo.coordinateBytes()] = blocks[blockFrom.coordinateBytes()];
        blocks[blockFrom.coordinateBytes()] = 0;
    }

    function avatarSet(
        uint256 avatarId,
        Block memory blockTo
    ) public onlyAvatar {
        blocks[blockTo.coordinateBytes()] = avatarId;
    }

    function avatarRemove(Block memory block_) public {
        blocks[block_.coordinateBytes()] = 0;
    }

    function getBlockAvatar(Block memory block_) public view returns (uint256) {
        return blocks[block_.coordinateBytes()];
    }

    function getBlockAttackRangeAvatars(
        Block memory block_
    ) public view returns (uint256[] memory) {
        uint256[] memory ringNums = new uint256[](2);
        ringNums[0] = 1;
        ringNums[0] = 2;
        return getBlocksAvatars(HexGridsMath.blockRingBlocks(block_, ringNums));
    }

    function getBlockSpheres(
        Block memory block_
    ) public pure returns (Block[] memory) {
        uint256[] memory ringNums = new uint256[](1);
        ringNums[0] = 1;
        return HexGridsMath.blockRingBlocks(block_, ringNums);
    }

    function getBlocksAvatars(
        Block[] memory blocks_
    ) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](blocks_.length);
        uint256 j = 0;
        bytes9 coordinate;
        uint256 i;
        for (i = 0; i < blocks_.length; i++) {
            coordinate = blocks_[i].coordinateBytes();
            if (blocks[coordinate] > 0) {
                avatarIds[j] = blocks[coordinate];
                j++;
            }
        }
        uint256[] memory nonzeroAvatarIds = new uint256[](j);
        for (i = 0; i < j; i++) {
            nonzeroAvatarIds[i] = avatarIds[i];
        }
        return nonzeroAvatarIds;
    }

    modifier onlyAvatar() {
        require(msg.sender == address(Avatar), "not allowed");
        _;
    }
}
