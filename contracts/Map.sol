// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPN.sol";
import "./libraries/HexGridsMath.sol";

contract Map {
    // Block => avatarId
    mapping(uint64 => uint256) public blocks;

    mapping(uint64 => uint256) public coblocks;

    mapping(uint64 => mapping(uint256 => uint256)) public coblocksExt;

    uint256[3] blers = [1, 5, 15];

    IAvatar public Avatar;
    IGovernance public Governance;

    function setGovernanceContract(address governanceContract_) public {
        Governance = IGovernance(governanceContract_);
        Avatar = IAvatar(Governance.avatarContract());
    }

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint64 blockCoordinate,
        uint16 blockPassId
    ) public onlyAvatar returns (uint256 bler) {
        require(getBlockAvatar(blockCoordinate) == 0, "dst Occupied");

        uint64[] memory blockSpheres = HexGridsMath.blockIntSpheres(
            blockCoordinate
        );
        uint256 coidcontext;
        for (uint256 i = 0; i < blockSpheres.length; i++) {
            coidcontext = getBlocksCOID(blockSpheres[i]);
            require(coidcontext == 0 || coidcontext == COID, "dst has enemy");
        }

        require(
            IntBlockMath.distance(
                blockCoordinate,
                BlockMath.coordinateInt(
                    HexGridsMath.PassCenterBlock(blockPassId)
                )
            ) < 6,
            "PassId error"
        );
        uint8 passType = HexGridsMath.getPassType(blockPassId);

        blocks[blockCoordinate] = avatarId;
        bler += coBlockAdd(blockCoordinate, COID, avatarId, passType);

        for (uint256 i = 0; i < 6; i++) {
            bler += coBlockAdd(blockSpheres[i], COID, avatarId, passType);
        }
    }

    function avatarRemove(
        uint64 block_,
        uint256 avatarId
    ) public onlyAvatar returns (uint256 bler) {
        blocks[block_] = 0;
        bler += coBlockSub(block_, avatarId);

        uint64[] memory blockSpheres = HexGridsMath.blockIntSpheres(block_);
        for (uint256 i = 0; i < 6; i++) {
            bler += coBlockSub(blockSpheres[i], avatarId);
        }
    }

    function coBlockAdd(
        uint64 blockcoordinate,
        uint256 COID,
        uint256 avatarId,
        uint256 blockType
    ) private returns (uint256 bler) {
        if (coblocks[blockcoordinate] == 0) {
            bler = blers[blockType];
            coblocks[blockcoordinate] = COID * 1000 + blockType * 10 + 1;
            coblocksExt[blockcoordinate][0] = avatarId;
        } else {
            uint64 index = uint64((coblocks[blockcoordinate] % 10));
            coblocksExt[blockcoordinate][index] = avatarId;
            coblocks[blockcoordinate]++;
        }
    }

    function coBlockSub(
        uint64 blockcoordinate,
        uint256 avatarId
    ) private returns (uint256 bler) {
        uint256 blockType = (coblocks[blockcoordinate] % 1000) / 10;
        bler = blers[blockType];
        uint256 left = (coblocks[blockcoordinate] % 10);
        if (left == 1) {
            coblocks[blockcoordinate] = 0;
        } else {
            uint256 substituteIndex = 0;
            for (uint256 i = 0; i < left; i++) {
                if (coblocksExt[blockcoordinate][i] == avatarId) {
                    if (i == 0) {
                        substituteIndex = i + 1;

                        Avatar.addBLER(
                            coblocksExt[blockcoordinate][substituteIndex],
                            bler
                        );
                    } else {
                        bler = 0;
                    }
                }
                if (substituteIndex > 0 && i >= substituteIndex) {
                    coblocksExt[blockcoordinate][i - 1] = coblocksExt[
                        blockcoordinate
                    ][i];
                }
            }
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

    function getBlocksCOID(
        uint64 blockcoordinates
    ) public view returns (uint256) {
        return
            coblocks[blockcoordinates] > 0
                ? coblocks[blockcoordinates] / 1000
                : 0;
    }

    function getBlocksCOIDs(
        uint64[] memory blockcoordinates
    ) public view returns (uint256[] memory) {
        uint256[] memory COIDs = new uint256[](blockcoordinates.length);
        for (uint256 i = 0; i < blockcoordinates.length; i++) {
            COIDs[i] = coblocks[blockcoordinates[i]] > 0
                ? coblocks[blockcoordinates[i]] / 1000
                : 0;
        }
        return COIDs;
    }

    modifier onlyAvatar() {
        require(msg.sender == address(Avatar), "not allowed");
        _;
    }
}
