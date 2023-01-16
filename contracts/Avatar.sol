// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "./libraries/HexGridsMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error linkBlockError();

contract Avatar is Multicall, Ownable {
    using BlockMath for Block;
    using Math for uint256;

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

    function addHP(uint256 avatarId, uint256 amount) public onlyOwner {
        avatarNoumenon[avatarId].HP += amount;
    }

    function addATT(uint256 avatarId, uint256 amount) public onlyOwner {
        avatarNoumenon[avatarId].ATT += amount;
    }

    function moveTo(
        Block memory block_,
        uint256 linkedAvatarId,
        uint256 avatarId,
        bool attack
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

        uint64[] memory blockSpheres;
        if (attack) {
            blockSpheres = HexGridsMath.blockSpiralRingBlockInts(block_, 2);

            if (attackEnemies(avatarId, blockSpheres) != BattleResult.Victory) {
                return;
            }
        } else {
            blockSpheres = HexGridsMath.blockIntSpheres(block_);
            uint256[] memory COIDs = Map.getBlocksCOIDs(blockSpheres);
            for (uint256 i = 0; i < COIDs.length; i++) {
                console.log(COIDs[i]);
                require(
                    COIDs[i] == 0 || COIDs[i] == avatarNoumenon[avatarId].COID,
                    "no attack failure"
                );
            }
        }

        uint8[] memory blockLevels = new uint8[](7);

        uint256 blerremove = 0;
        if (avatarNoumenon[avatarId].blockCoordinatInt != 0) {
            blerremove = Map.avatarRemove(
                avatarNoumenon[avatarId].blockCoordinatInt
            );
        }

        avatarNoumenon[avatarId].blockCoordinatInt = block_.coordinateInt();

        uint256 bleradd = Map.avatarSet(
            avatarId,
            avatarNoumenon[avatarId].COID,
            avatarNoumenon[avatarId].blockCoordinatInt,
            blockSpheres,
            blockLevels
        );
        if (bleradd < blerremove) {
            Governance.SubCollectionBLER(
                avatarNoumenon[avatarId].COID,
                blerremove - bleradd
            );
        } else if (bleradd > blerremove) {
            Governance.addCollectionBLER(
                avatarNoumenon[avatarId].COID,
                bleradd - blerremove
            );
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
        battleRes = BattleResult.Victory;
        uint256 attackAvatarId;
        for (uint256 i = 0; i < blockAttackRange.length; i++) {
            attackAvatarId = Map.getBlockAvatar(blockAttackRange[i]);
            if (
                attackAvatarId == 0 ||
                avatarNoumenon[attackAvatarId].COID == avatarData.COID
            ) {
                continue;
            }
            battleRes = attackEnemy(avatarId, attackAvatarId);
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
        if (
            avatarNoumenon[avatarId].ATT == 0 &&
            avatarNoumenon[enemyAvatarId].ATT == 0
        ) {
            return BattleResult.Draw;
        }
        if (avatarNoumenon[avatarId].ATT == 0) {
            deFeat(avatarId);
            return BattleResult.Defeat;
        } else if (avatarNoumenon[enemyAvatarId].ATT == 0) {
            deFeat(enemyAvatarId);
            return BattleResult.Victory;
        } else {
            uint256 enemyAttack = avatarNoumenon[avatarId].HP.ceilDiv(
                avatarNoumenon[enemyAvatarId].ATT
            );
            uint256 avatarAttack = avatarNoumenon[enemyAvatarId].HP.ceilDiv(
                avatarNoumenon[avatarId].ATT
            );
            if (enemyAttack > avatarAttack) {
                avatarNoumenon[avatarId].HP -=
                    avatarNoumenon[enemyAvatarId].ATT *
                    avatarAttack;
                deFeat(enemyAvatarId);
                return BattleResult.Victory;
            } else if (enemyAttack < avatarAttack) {
                avatarNoumenon[enemyAvatarId].HP -=
                    avatarNoumenon[avatarId].ATT *
                    enemyAttack;
                deFeat(avatarId);
                return BattleResult.Defeat;
            } else {
                deFeat(avatarId);
                deFeat(enemyAvatarId);
                return BattleResult.NoWin;
            }
        }
    }

    function deFeat(uint256 avatarId) internal {
        Governance.SubCollectionBLER(
            avatarNoumenon[avatarId].COID,
            Map.avatarRemove(avatarNoumenon[avatarId].blockCoordinatInt)
        );
        avatarNoumenon[avatarId].blockCoordinatInt = 0;
        avatarNoumenon[avatarId].HP = 1;
        avatarNoumenon[avatarId].ATT = 0;
        claimEnergy(avatarId);
    }

    function claimEnergy(uint256 avatarId) public {}

    modifier blockCheck(Block memory block_) {
        block_.check();
        require(
            Map.getBlockAvatar(block_.coordinateInt()) == 0,
            "block not available"
        );
        _;
    }
}
