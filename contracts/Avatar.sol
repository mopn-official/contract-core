// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "./libraries/IntBlockMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract Avatar is Multicall, Ownable {
    using Math for uint256;
    using IntBlockMath for uint32;

    mapping(uint256 => AvatarData) public avatarNoumenon;

    mapping(uint256 => mapping(uint256 => uint256)) public tokenMap;

    mapping(uint256 => uint256) public collectionMap;

    IMap public Map;

    IGovernance public Governance;

    uint256 public currentAvatarId;

    function setGovernanceContract(address governanceContract_) public {
        Governance = IGovernance(governanceContract_);
        Map = IMap(Governance.mapContract());
    }

    function getAvatarOccupiedBlock(
        uint256 avatarId
    ) public view returns (uint32) {
        return avatarNoumenon[avatarId].blockCoordinate;
    }

    function getAvatarCOID(uint256 avatarId) public view returns (uint256) {
        return avatarNoumenon[avatarId].COID;
    }

    function ownerOf(uint256 avatarId) public view returns (address) {
        require(avatarNoumenon[avatarId].COID > 0, "avatar not exist");
        return
            IERC721(
                Governance.getCollectionContract(avatarNoumenon[avatarId].COID)
            ).ownerOf(avatarNoumenon[avatarId].tokenId);
    }

    function mintAvatar(
        address collectionContract,
        uint256 tokenId,
        bytes32[] memory proofs
    ) public returns (uint256) {
        require(
            msg.sender == IERC721(collectionContract).ownerOf(tokenId),
            "caller is not token owner"
        );
        uint256 COID = Governance.checkWhitelistCOID(
            collectionContract,
            proofs
        );
        require(tokenMap[COID][tokenId] == 0, "avatar exist");

        currentAvatarId++;

        avatarNoumenon[currentAvatarId].COID = COID;
        avatarNoumenon[currentAvatarId].tokenId = tokenId;

        tokenMap[COID][tokenId] = currentAvatarId;
        return currentAvatarId;
    }

    function jumpIn(
        uint32 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId,
        uint32 PassId
    )
        public
        blockCheck(blockCoordinate)
        ownerCheck(avatarId)
        linkCheck(blockCoordinate, linkedAvatarId, avatarId)
    {
        require(
            avatarNoumenon[avatarId].blockCoordinate == 0,
            "avatar is on map"
        );

        Map.avatarSet(
            avatarId,
            avatarNoumenon[avatarId].COID,
            blockCoordinate,
            PassId,
            avatarNoumenon[avatarId].BoomUsed
        );

        avatarNoumenon[avatarId].blockCoordinate = blockCoordinate;
        Governance.redeemCollectionInboxEnergy(
            avatarId,
            avatarNoumenon[avatarId].COID,
            collectionMap[avatarNoumenon[avatarId].COID]
        );
        collectionMap[avatarNoumenon[avatarId].COID]++;
    }

    function moveTo(
        uint32 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId,
        uint32 PassId
    )
        public
        blockCheck(blockCoordinate)
        ownerCheck(avatarId)
        linkCheck(blockCoordinate, linkedAvatarId, avatarId)
    {
        require(
            avatarNoumenon[avatarId].blockCoordinate != 0,
            "avatar not on map"
        );
        Map.avatarRemove(
            avatarId,
            avatarNoumenon[avatarId].COID,
            avatarNoumenon[avatarId].blockCoordinate
        );

        Map.avatarSet(
            avatarId,
            avatarNoumenon[avatarId].COID,
            blockCoordinate,
            PassId,
            0
        );

        avatarNoumenon[avatarId].blockCoordinate = blockCoordinate;
    }

    function bomb(
        uint32 blockCoordinate,
        uint256 avatarId
    ) public blockCheck(blockCoordinate) ownerCheck(avatarId) {
        avatarNoumenon[avatarId].BoomUsed++;
        if (avatarNoumenon[avatarId].blockCoordinate > 0) {
            Governance.burnBomb(
                msg.sender,
                1,
                avatarId,
                avatarNoumenon[avatarId].COID,
                Map.getBlockPassId(avatarNoumenon[avatarId].blockCoordinate)
            );
        } else {
            Governance.burnBomb(msg.sender, 1, 0, 0, 0);
        }

        uint256 attackAvatarId;
        for (uint256 i = 0; i < 7; i++) {
            attackAvatarId = Map.getBlockAvatar(blockCoordinate);
            if (i == 0) {
                blockCoordinate = blockCoordinate.neighbor(4);
            } else {
                blockCoordinate = blockCoordinate.neighbor(i - 1);
            }
            if (attackAvatarId == 0 || attackAvatarId == avatarId) {
                continue;
            }
            deFeat(attackAvatarId);
        }
    }

    function deFeat(uint256 avatarId) internal {
        Map.avatarRemove(
            avatarId,
            avatarNoumenon[avatarId].COID,
            avatarNoumenon[avatarId].blockCoordinate
        );
        avatarNoumenon[avatarId].blockCoordinate = 0;
        collectionMap[avatarNoumenon[avatarId].COID]--;
    }

    modifier ownerCheck(uint256 avatarId) {
        require(ownerOf(avatarId) == msg.sender, "not your avatar");
        _;
    }

    modifier blockCheck(uint32 blockCoordinate) {
        blockCoordinate.check();
        _;
    }

    modifier linkCheck(
        uint32 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId
    ) {
        require(avatarNoumenon[avatarId].COID > 0, "avatar not exist");

        if (linkedAvatarId > 0) {
            require(
                avatarNoumenon[avatarId].COID ==
                    avatarNoumenon[linkedAvatarId].COID,
                "link co error"
            );
            require(linkedAvatarId != avatarId, "link to yourself");
            if (
                blockCoordinate.distance(
                    avatarNoumenon[linkedAvatarId].blockCoordinate
                ) > 3
            ) {
                revert linkBlockError();
            }
        } else if (collectionMap[avatarNoumenon[avatarId].COID] > 0) {
            if (
                !(avatarNoumenon[avatarId].blockCoordinate > 0 &&
                    collectionMap[avatarNoumenon[avatarId].COID] == 1)
            ) {
                revert linkBlockError();
            }
        }
        _;
    }

    modifier onlyMap() {
        require(
            msg.sender == address(Map) || msg.sender == address(this),
            "not allowed"
        );
        _;
    }
}
