// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "./libraries/HexGridsMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

error linkBlockError();

contract Avatar is Multicall {
    using BlockMath for Block;

    mapping(uint256 => AvatarData) public avatarNoumenon;

    mapping(uint256 => mapping(uint256 => uint256)) public tokenMap;

    mapping(uint256 => uint256) public collectionMap;

    IMap public Map;

    IGovernance public Governance;

    uint256 public currentAvatarId;

    constructor(address governanceContract_, address mapContract_) {
        Map = IMap(mapContract_);
        Governance = IGovernance(governanceContract_);
    }

    function getAvatarOccupiedBlock(
        uint256 avatarId
    ) public view returns (Block memory) {
        return
            BlockMath.fromCoordinateInt(
                avatarNoumenon[avatarId].blockCoordinatInt
            );
    }

    function getAvatarOccupiedBlockInt(
        uint256 avatarId
    ) public view returns (uint64) {
        return avatarNoumenon[avatarId].blockCoordinatInt;
    }

    function mintAvatar(
        NFToken calldata token_,
        bytes32[] memory proofs
    ) public returns (uint256) {
        uint256 COID = Governance.checkWhitelistCOID(
            token_.collectionContract,
            proofs
        );
        require(tokenMap[COID][token_.tokenId] == 0, "avatar exist");

        currentAvatarId++;

        avatarNoumenon[currentAvatarId].COID = COID;
        avatarNoumenon[currentAvatarId].tokenId = token_.tokenId;

        tokenMap[COID][token_.tokenId] = currentAvatarId;
        return currentAvatarId;
    }

    function moveTo(
        Block memory block_,
        uint16[] memory PassIds,
        uint8[] memory spheresPassIds,
        uint256 linkedAvatarId,
        uint256 avatarId
    ) public blockCheck(block_) {
        if (linkedAvatarId > 0) {
            if (
                block_.distance(
                    BlockMath.fromCoordinateInt(
                        avatarNoumenon[linkedAvatarId].blockCoordinatInt
                    )
                ) > 3
            ) {
                revert linkBlockError();
            }
        } else if (collectionMap[avatarNoumenon[avatarId].COID] > 0) {
            revert linkBlockError();
        }

        uint64[] memory blockIntAttackRange = getBlockAttackRange(block_);

        if (
            attackEnemies(avatarId, blockIntAttackRange) == BattleResult.Victory
        ) {
            bytes32[] memory randomseed = new bytes32[](3);
            Block[] memory centerBlocks = new Block[](3);

            uint256 i;
            for (i = 0; i < PassIds.length; i++) {
                randomseed[i] = keccak256(
                    abi.encodePacked(Governance.passContract(), PassIds[i])
                );
                centerBlocks[i] = HexGridsMath.PassCenterBlock(PassIds[i]);
            }

            uint8[] memory blockLevels = new uint8[](7);
            blockLevels[0] = HexGridsMath.blockLevel(
                randomseed[spheresPassIds[0]],
                HexGridsMath.blockIndex(block_, centerBlocks[spheresPassIds[0]])
            );
            for (i = 1; i < 7; i++) {
                blockLevels[i] = HexGridsMath.blockLevel(
                    randomseed[spheresPassIds[i]],
                    HexGridsMath.blockIndex(
                        BlockMath.fromCoordinateInt(blockIntAttackRange[i]),
                        centerBlocks[spheresPassIds[i]]
                    )
                );
            }

            if (avatarNoumenon[avatarId].blockCoordinatInt != 0) {
                Map.avatarRemove(avatarNoumenon[avatarId].blockCoordinatInt);
            }

            avatarNoumenon[avatarId].blockCoordinatInt = block_.coordinateInt();

            Map.avatarSet(
                avatarId,
                avatarNoumenon[avatarId].COID,
                avatarNoumenon[avatarId].blockCoordinatInt,
                blockIntAttackRange,
                blockLevels
            );
        } else {
            deFeat(avatarId);
        }
    }

    enum BattleResult {
        Defeat,
        Victory,
        NoWin,
        Draw
    }

    function attackEnemies(
        uint256 avatarId,
        uint64[] memory blockAttackRange
    ) internal returns (BattleResult battleRes) {
        AvatarData memory avatarData = avatarNoumenon[avatarId];
        uint256[] memory attackAvatarIds = Map.getBlocksAvatars(
            blockAttackRange
        );
        battleRes = BattleResult.Victory;
        for (uint256 i = 0; i < attackAvatarIds.length; i++) {
            if (
                attackAvatarIds[i] == 0 ||
                avatarNoumenon[attackAvatarIds[i]].COID == avatarData.COID
            ) {
                continue;
            }
            battleRes = attackEnemy(avatarId, attackAvatarIds[i]);
            if (BattleResult.Victory != battleRes) {
                break;
            }
        }
        require(battleRes != BattleResult.Draw, "draw battle");
    }

    function attackEnemy(
        uint256 avatarId,
        uint256 enemyAvatarId
    ) public returns (BattleResult batteRes) {
        //todo battle
        if (
            avatarNoumenon[avatarId].ATT == 0 &&
            avatarNoumenon[enemyAvatarId].ATT == 0
        ) {
            return BattleResult.Draw;
        }
        deFeat(enemyAvatarId);
        return BattleResult.Victory;
    }

    function deFeat(uint256 avatarId) internal {
        Map.avatarRemove(avatarNoumenon[avatarId].blockCoordinatInt);
        avatarNoumenon[avatarId].blockCoordinatInt = 0;
        claimEnergy(avatarId);
    }

    function claimEnergy(uint256 avatarId) public {}

    function getBlockAttackRange(
        Block memory block_
    ) public pure returns (uint64[] memory) {
        return HexGridsMath.blockSpiralRingBlockInts(block_, 2);
    }

    modifier blockCheck(Block memory block_) {
        block_.check();
        require(
            Map.getBlockAvatar(block_.coordinateInt()) == 0,
            "block not available"
        );
        _;
    }
}
