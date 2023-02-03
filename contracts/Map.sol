// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPN.sol";
import "./libraries/IntBlockMath.sol";

contract Map {
    using IntBlockMath for uint64;

    // Block => avatarId
    mapping(uint64 => uint256) public blocks;

    mapping(uint64 => uint64) public blocksInPass;

    uint256[3] BEPSs = [1, 5, 15];

    IAvatar public Avatar;
    IGovernance public Governance;

    function setGovernanceContract(address governanceContract_) public {
        Governance = IGovernance(governanceContract_);
        Avatar = IAvatar(Governance.avatarContract());
    }

    function PassData2Ids(
        bytes memory b
    ) internal pure returns (uint64[3] memory PassIds) {
        for (uint i = 0; i < 3; i++) {
            PassIds[i] =
                uint64(uint8(b[i * 2])) *
                256 +
                uint64(uint8(b[i * 2 + 1]));
        }
    }

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint64 blockCoordinate,
        bytes memory PassData
    ) public onlyAvatar {
        require(Map.getBlockAvatar(blockCoordinate) == 0, "dst Occupied");

        uint64[3] memory PassIds = PassData2Ids(PassData);
        blocks[blockCoordinate] = avatarId * 10000000000 + block.timestamp;

        uint256 BEPS;
        uint64 PassId;
        for (uint256 i = 0; i < 7; i++) {
            if (blocksInPass[blockCoordinate] > 0) {
                PassId = blocksInPass[blockCoordinate];
            } else {
                PassId = PassIds[uint8(PassData[i + 6])];
                require(
                    blockCoordinate.distance(
                        IntBlockMath.PassCenterBlock(PassId)
                    ) < 6,
                    "PassId error"
                );
                blocksInPass[blockCoordinate] = PassId;
            }

            BEPS = coBlockAdd(blockCoordinate, COID, PassId, i);
            if (BEPS > 0) {
                Governance.addBEPS(avatarId, COID, PassId, BEPS);
            }
            if (i == 0) {
                blockCoordinate = blockCoordinate.neighbor(4);
            } else {
                blockCoordinate = blockCoordinate.neighbor(i - 1);
            }
        }
    }

    function avatarRemove(
        uint256 avatarId,
        uint256 COID,
        uint64 blockCoordinate
    ) public onlyAvatar {
        uint256 occupiedTimestamp = getBlockOccupiedTimestamp(blockCoordinate);
        blocks[blockCoordinate] = 0;

        uint256 BEPS;
        for (uint256 i = 0; i < 7; i++) {
            BEPS = coBlockSub(
                blockCoordinate,
                COID,
                blocksInPass[blockCoordinate],
                occupiedTimestamp,
                i
            );
            if (BEPS > 0) {
                Governance.subBEPS(
                    avatarId,
                    COID,
                    blocksInPass[blockCoordinate],
                    BEPS
                );
            }
            if (i == 0) {
                blockCoordinate = blockCoordinate.neighbor(4);
            } else {
                blockCoordinate = blockCoordinate.neighbor(i - 1);
            }
        }
    }

    function getBlockOuterDirections(
        uint256 Index
    ) public pure returns (uint8[4] memory a) {
        if (Index == 1) {
            return [3, 5, 0, 0];
        } else if (Index == 2) {
            return [4, 0, 1, 0];
        } else if (Index == 3) {
            return [5, 1, 2, 0];
        } else if (Index == 4) {
            return [0, 2, 3, 0];
        } else if (Index == 5) {
            return [1, 3, 4, 0];
        } else if (Index == 6) {
            return [2, 4, 5, 0];
        }
    }

    function coBlockAdd(
        uint64 blockCoordinate,
        uint256 COID,
        uint64 PassId,
        uint256 Index
    ) private view returns (uint256 BEPS) {
        BEPS = BEPSs[IntBlockMath.getPassType(PassId)];
        if (Index != 0) {
            uint8[4] memory directions = getBlockOuterDirections(Index);
            for (uint256 i = 0; i < directions.length; i++) {
                uint256 coAvatarId = getBlockAvatar(blockCoordinate);
                if (coAvatarId > 0) {
                    require(
                        Avatar.getAvatarCOID(coAvatarId) == COID,
                        "dst has enemy"
                    );
                    BEPS = 0;
                    break;
                }

                blockCoordinate = blockCoordinate.neighbor(directions[i]);
            }
        }
    }

    function coBlockSub(
        uint64 blockCoordinate,
        uint256 COID,
        uint64 PassId,
        uint256 occupiedTimestamp,
        uint256 Index
    ) private returns (uint256 BEPS) {
        BEPS = BEPSs[IntBlockMath.getPassType(PassId)];
        if (Index != 0) {
            uint256 substituteAvatarId;
            uint256 substituteOccupiedTimestamp;
            uint256 substituteBEPS;
            uint8[4] memory directions = getBlockOuterDirections(Index);
            for (uint256 i = 0; i < directions.length; i++) {
                uint256 coAvatarId = getBlockAvatar(blockCoordinate);
                if (coAvatarId > 0) {
                    if (i == 0) {
                        BEPS = 0;
                        break;
                    }
                    uint256 coOccupiedTimestamp = getBlockOccupiedTimestamp(
                        blockCoordinate
                    );
                    if (coOccupiedTimestamp < occupiedTimestamp) {
                        BEPS = 0;
                        break;
                    } else if (
                        substituteOccupiedTimestamp == 0 ||
                        coOccupiedTimestamp < substituteOccupiedTimestamp
                    ) {
                        substituteOccupiedTimestamp = coOccupiedTimestamp;
                        substituteAvatarId = coAvatarId;
                        substituteBEPS = BEPSs[
                            IntBlockMath.getPassType(PassId)
                        ];
                    }
                }

                blockCoordinate = blockCoordinate.neighbor(directions[i]);
            }
            if (substituteAvatarId > 0) {
                Governance.addBEPS(
                    substituteAvatarId,
                    COID,
                    PassId,
                    substituteBEPS
                );
            }
        }
    }

    function getBlockAvatar(
        uint64 blockCoordinate
    ) public view returns (uint256) {
        return blocks[blockCoordinate] / 10000000000;
    }

    function getBlockOccupiedTimestamp(
        uint64 blockCoordinate
    ) public view returns (uint256) {
        return (blocks[blockCoordinate] % 10000000000);
    }

    function getBlocksAvatars(
        uint64[] memory blockcoordinates
    ) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](blockcoordinates.length);
        for (uint256 i = 0; i < blockcoordinates.length; i++) {
            avatarIds[i] = blocks[blockcoordinates[i]] / 10000000000;
        }
        return avatarIds;
    }

    modifier onlyAvatar() {
        require(msg.sender == address(Avatar), "not allowed");
        _;
    }
}
