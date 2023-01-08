// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "./libraries/BlockMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

struct MoveParams {
    Block block_;
    uint256 linkedAvatarId;
    uint256 avatarId;
    NFToken token_;
}

error linkBlockError();

contract Avatar is ERC721 {
    using BlockMath for Block;

    mapping(uint256 => AvatarData) public avatarNoumenon;

    mapping(address => mapping(uint256 => uint256)) public tokenMap;

    mapping(address => uint256) public collectionMap;

    IMap public Map;

    uint256 public currentTokenId;

    constructor(
        string memory name_,
        string memory symbol_,
        address mapContract_
    ) ERC721(name_, symbol_) {
        Map = IMap(mapContract_);
    }

    function getAvatarOccupiedBlock(
        uint256 avatarId
    ) public view returns (Block memory) {
        return avatarNoumenon[avatarId].block_;
    }

    function getAvatarSphereBlocks(
        uint256 avatarId
    ) public view returns (Block[] memory) {
        return Map.getBlockSpheres(getAvatarOccupiedBlock(avatarId));
    }

    function mintAvatar(NFToken calldata token_) public returns (uint256) {
        currentTokenId++;
        _mint(msg.sender, currentTokenId);
        avatarNoumenon[currentTokenId].token_ = token_;
        tokenMap[token_.collectionContract][token_.tokenId] = currentTokenId;
        return currentTokenId;
    }

    function moveTo(
        MoveParams calldata moveParams
    ) public linkBlockCheck(moveParams) blockCheck(moveParams.block_) {
        attackEnemies(
            moveParams.avatarId,
            Map.getBlockAttackRangeAvatars(moveParams.block_)
        );

        Map.avatarMove(
            avatarNoumenon[moveParams.avatarId].block_,
            moveParams.block_
        );
        avatarNoumenon[moveParams.avatarId].block_ = moveParams.block_;
    }

    function jumpIn(
        MoveParams calldata moveParams
    ) public linkBlockCheck(moveParams) blockCheck(moveParams.block_) {
        uint256 avatarId = tokenMap[moveParams.token_.collectionContract][
            moveParams.token_.tokenId
        ];
        if (avatarId == 0) {
            avatarId = mintAvatar(moveParams.token_);
        } else {
            require(
                avatarNoumenon[avatarId].block_.equals(Block(0, 0, 0)),
                "avatar is in map"
            );
        }

        attackEnemies(
            avatarId,
            Map.getBlockAttackRangeAvatars(moveParams.block_)
        );

        Map.avatarSet(avatarId, moveParams.block_);
        collectionMap[moveParams.token_.collectionContract]++;
        avatarNoumenon[avatarId].block_ = moveParams.block_;
    }

    function attackEnemies(
        uint256 avatarId,
        uint256[] memory attachAvatarIds
    ) public {
        AvatarData memory avatarData = avatarNoumenon[avatarId];
        for (uint256 i = 0; i < attachAvatarIds.length; i++) {
            if (
                avatarNoumenon[attachAvatarIds[i]].token_.collectionContract ==
                avatarData.token_.collectionContract
            ) {
                continue;
            }
            if (!attackEnemy(avatarId, attachAvatarIds[i])) {
                avatarNoumenon[avatarId].block_ = Block(0, 0, 0);
                break;
            }
        }
    }

    function attackEnemy(
        uint256 avatarId,
        uint256 enemyAvatarId
    ) public returns (bool) {
        //todo battle
        avatarNoumenon[enemyAvatarId].block_ = Block(0, 0, 0);
        return true;
    }

    function claimEnergy(uint256 avatarId) public {}

    modifier linkBlockCheck(MoveParams calldata moveParams) {
        if (moveParams.linkedAvatarId > 0) {
            if (
                moveParams.block_.distance(
                    avatarNoumenon[moveParams.linkedAvatarId].block_
                ) > 2
            ) {
                revert linkBlockError();
            }
        } else if (moveParams.token_.collectionContract != address(0)) {
            if (collectionMap[moveParams.token_.collectionContract] > 0) {
                revert linkBlockError();
            }
        } else {
            revert linkBlockError();
        }
        _;
    }

    modifier blockCheck(Block memory block_) {
        block_.check();
        require(Map.getBlockAvatar(block_) == 0, "block not available");
        _;
    }
}
