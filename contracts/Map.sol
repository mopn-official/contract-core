// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPN.sol";
import "./libraries/HexGridsMath.sol";

contract Map {
    using BlockMath for Block;
    // Block => avatarId
    mapping(uint256 => uint256) public blocks;

    mapping(uint256 => uint256) public coblocks;

    uint256[12] blockLevel = [
        125000000000000000,
        250000000000000000,
        375000000000000000,
        500000000000000000,
        625000000000000000,
        750000000000000000,
        875000000000000000,
        1000000000000000000,
        1125000000000000000,
        1250000000000000000,
        1375000000000000000,
        1500000000000000000
    ];

    IAvatar public Avatar;

    function setAvatarContract(address avatarContract_) public {
        Avatar = IAvatar(avatarContract_);
    }

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        Block memory blockTo
    ) public onlyAvatar {
        blocks[blockTo.coordinateInt()] = avatarId;
        coBlockAdd(blockTo.coordinateInt(), COID);
        Block[] memory blockSpheres = HexGridsMath.blockSpheres(blockTo);
        for (uint256 i; i < blockSpheres.length; i++) {
            coBlockAdd(blockSpheres[i].coordinateInt(), COID);
        }
    }

    function avatarRemove(Block memory block_, uint256 COID) public {
        blocks[block_.coordinateInt()] = 0;
        coBlockSub(block_.coordinateInt(), COID);
        Block[] memory blockSpheres = HexGridsMath.blockSpheres(block_);
        for (uint256 i; i < blockSpheres.length; i++) {
            coBlockSub(blockSpheres[i].coordinateInt(), COID);
        }
    }

    function coBlockAdd(uint256 blockcoordinate, uint256 COID) private {
        coblocks[blockcoordinate] =
            COID *
            10 +
            (coblocks[blockcoordinate] % 10) +
            1;
    }

    function coBlockSub(uint256 blockcoordinate, uint256 COID) private {
        uint256 left = (coblocks[blockcoordinate] % 10);
        if (left == 0 || left == 1) {
            coblocks[blockcoordinate] = 0;
        } else {
            coblocks[blockcoordinate] = COID * 10 + left - 1;
        }
    }

    function getBlockAvatar(Block memory block_) public view returns (uint256) {
        return blocks[block_.coordinateInt()];
    }

    function getBlocksAvatars(
        Block[] memory blocks_
    ) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](blocks_.length);
        for (uint256 i = 0; i < blocks_.length; i++) {
            avatarIds[i] = blocks[blocks_[i].coordinateInt()];
        }
        return avatarIds;
    }

    modifier onlyAvatar() {
        require(msg.sender == address(Avatar), "not allowed");
        _;
    }
}
