// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPN.sol";
import "./libraries/HexGridsMath.sol";

contract Map {
    using BlockMath for Block;
    // Block => avatarId
    mapping(uint64 => uint256) public blocks;

    mapping(uint64 => uint256) public coblocks;

    uint256[12] blers = [
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
    IGovernance public Governance;

    function setAvatarContract(address avatarContract_) public {
        Avatar = IAvatar(avatarContract_);
    }

    function setGovernanceContract(address governanceContract) public {
        Governance = IGovernance(governanceContract);
    }

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint64 blockTo,
        uint64[] memory blockSpheres,
        uint8[] memory blockLevels
    ) public onlyAvatar returns (uint256 bler) {
        blocks[blockTo] = avatarId;
        bler += coBlockAdd(blockTo, COID, blockLevels[0]);
        for (uint256 i = 0; i < 6; i++) {
            bler += coBlockAdd(blockSpheres[i], COID, blockLevels[i + 1]);
        }
        if (bler > 0) {
            Governance.addCollectionBLER(COID, bler);
        }
    }

    function avatarRemove(uint64 block_) public {
        blocks[block_] = 0;
        coBlockSub(block_);
        uint64[] memory blockSpheres = HexGridsMath.blockIntSpheres(
            BlockMath.fromCoordinateInt(block_)
        );
        for (uint256 i = 0; i < 6; i++) {
            coBlockSub(blockSpheres[i]);
        }
    }

    function coBlockAdd(
        uint64 blockcoordinate,
        uint256 COID,
        uint8 blockLevel
    ) private returns (uint256 bler) {
        if (coblocks[blockcoordinate] == 0) {
            bler = blers[blockLevel - 1];
        }
        coblocks[blockcoordinate] =
            COID *
            1000 +
            blockLevel *
            10 +
            (coblocks[blockcoordinate] % 10) +
            1;
    }

    function coBlockSub(uint64 blockcoordinate) private returns (uint256 bler) {
        uint256 left = (coblocks[blockcoordinate] % 10);
        if (left == 0 || left == 1) {
            uint256 blockLevel = (coblocks[blockcoordinate] % 1000) / 10;
            bler = blers[blockLevel - 1];
            coblocks[blockcoordinate] = 0;
        } else {
            coblocks[blockcoordinate] -= 1;
        }
    }

    function getBlockAvatar(uint64 block_) public view returns (uint256) {
        return blocks[block_];
    }

    function getBlocksAvatars(
        uint64[] memory blockcoordinates
    ) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](blockcoordinates.length);
        for (uint256 i = 0; i < blockcoordinates.length; i++) {
            avatarIds[i] = blocks[blockcoordinates[i]];
        }
        return avatarIds;
    }

    modifier onlyAvatar() {
        require(msg.sender == address(Avatar), "not allowed");
        _;
    }
}
