// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "./libraries/HexGridsMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

error linkBlockError();

contract Avatar is ERC721, Multicall {
    using BlockMath for Block;

    mapping(uint256 => AvatarData) public avatarNoumenon;

    mapping(uint256 => mapping(uint256 => uint256)) public tokenMap;

    mapping(uint256 => uint256) public collectionMap;

    IMap public Map;

    IGovernance public Governance;

    uint256 public currentTokenId;

    constructor(
        string memory name_,
        string memory symbol_,
        address governanceContract_,
        address mapContract_
    ) ERC721(name_, symbol_) {
        Map = IMap(mapContract_);
        Governance = IGovernance(governanceContract_);
    }

    function getAvatarOccupiedBlock(
        uint256 avatarId
    ) public view returns (Block memory) {
        return avatarNoumenon[avatarId].block_;
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

        currentTokenId++;
        _mint(msg.sender, currentTokenId);

        avatarNoumenon[currentTokenId].COID = COID;
        avatarNoumenon[currentTokenId].tokenId = token_.tokenId;

        tokenMap[COID][token_.tokenId] = currentTokenId;
        return currentTokenId;
    }

    function moveTo(
        Block memory block_,
        uint256 linkedAvatarId,
        uint256 avatarId
    ) public blockCheck(block_) {
        if (linkedAvatarId > 0) {
            if (block_.distance(avatarNoumenon[linkedAvatarId].block_) > 3) {
                revert linkBlockError();
            }
        } else if (collectionMap[avatarNoumenon[avatarId].COID] > 0) {
            revert linkBlockError();
        }

        Block[] memory blockAttackRange = getBlockAttackRange(block_);
        BattleResult battleRes = attackEnemies(avatarId, blockAttackRange);
        require(battleRes != BattleResult.Draw, "draw battle");
        if (battleRes == BattleResult.Victory) {
            if (!avatarNoumenon[avatarId].block_.equals(Block(0, 0, 0))) {
                Map.avatarRemove(
                    avatarNoumenon[avatarId].block_,
                    avatarNoumenon[avatarId].COID
                );
            }

            Map.avatarSet(avatarId, avatarNoumenon[avatarId].COID, block_);
            avatarNoumenon[avatarId].block_ = block_;
        } else {
            removeOut(avatarId);
        }
    }

    function test(uint256 a) public pure returns (uint256) {
        return a / 10000;
    }

    enum BattleResult {
        Defeat,
        Victory,
        NoWin,
        Draw
    }

    function attackEnemies(
        uint256 avatarId,
        Block[] memory blockAttackRange
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
        removeOut(enemyAvatarId);
        return BattleResult.Victory;
    }

    function removeOut(uint256 avatarId) internal {
        Map.avatarRemove(
            avatarNoumenon[avatarId].block_,
            avatarNoumenon[avatarId].COID
        );
        avatarNoumenon[avatarId].block_ = Block(0, 0, 0);
        claimEnergy(avatarId);
    }

    function claimEnergy(uint256 avatarId) public {}

    function getBlockAttackRange(
        Block memory block_
    ) public pure returns (Block[] memory) {
        uint256[] memory ringNums = new uint256[](2);
        ringNums[0] = 1;
        ringNums[0] = 2;
        return HexGridsMath.blockRingBlocks(block_, ringNums);
    }

    function getBlockSpheres(
        Block memory block_
    ) public pure returns (Block[] memory) {
        return HexGridsMath.blockSpheres(block_);
    }

    modifier blockCheck(Block memory block_) {
        block_.check();
        require(Map.getBlockAvatar(block_) == 0, "block not available");
        _;
    }
}
