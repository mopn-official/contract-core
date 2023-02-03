// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "./libraries/IntBlockMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error linkBlockError();

contract Avatar is Multicall, Ownable {
    using Math for uint256;
    using IntBlockMath for uint64;

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
    ) public view returns (uint64) {
        return avatarNoumenon[avatarId].blockCoordinatInt;
    }

    function getAvatarCOID(uint256 avatarId) public view returns (uint256) {
        return avatarNoumenon[avatarId].COID;
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

    function jumpIn(
        uint64 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId,
        bytes memory PassData
    )
        public
        blockCheck(blockCoordinate)
        linkCheck(blockCoordinate, linkedAvatarId, avatarId)
    {
        Map.avatarSet(
            avatarId,
            avatarNoumenon[avatarId].COID,
            blockCoordinate,
            PassData
        );

        avatarNoumenon[avatarId].blockCoordinatInt = blockCoordinate;
    }

    function moveTo(
        uint64 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId,
        bytes memory PassData
    )
        public
        blockCheck(blockCoordinate)
        linkCheck(blockCoordinate, linkedAvatarId, avatarId)
    {
        require(
            avatarNoumenon[avatarId].blockCoordinatInt != 0,
            "avatar not on map"
        );
        Map.avatarRemove(
            avatarId,
            avatarNoumenon[avatarId].COID,
            avatarNoumenon[avatarId].blockCoordinatInt
        );

        Map.avatarSet(
            avatarId,
            avatarNoumenon[avatarId].COID,
            blockCoordinate,
            PassData
        );

        avatarNoumenon[avatarId].blockCoordinatInt = blockCoordinate;
    }

    function bomb(
        uint64 blockCoordinate,
        uint256 avatarId
    ) public blockCheck(blockCoordinate) {
        Governance.burnBomb(msg.sender, 1);

        uint256 attackAvatarId;
        for (uint256 i = 0; i < 7; i++) {
            attackAvatarId = Map.getBlockAvatar(blockCoordinate);
            if (attackAvatarId == 0 || attackAvatarId == avatarId) {
                continue;
            }
            deFeat(attackAvatarId);
            if (i == 0) {
                blockCoordinate = blockCoordinate.neighbor(4);
            } else {
                blockCoordinate = blockCoordinate.neighbor(i - 1);
            }
        }
    }

    function deFeat(uint256 avatarId) internal {
        require(
            avatarNoumenon[avatarId].blockCoordinatInt > 0,
            "avatar not on map"
        );
        Map.avatarRemove(
            avatarId,
            avatarNoumenon[avatarId].COID,
            avatarNoumenon[avatarId].blockCoordinatInt
        );
        avatarNoumenon[avatarId].blockCoordinatInt = 0;
    }

    function claimEnergy(uint256 avatarId) public {}

    modifier blockCheck(uint64 blockCoordinate) {
        blockCoordinate.check();
        _;
    }

    modifier linkCheck(
        uint64 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId
    ) {
        if (linkedAvatarId > 0) {
            require(
                avatarNoumenon[avatarId].COID ==
                    avatarNoumenon[linkedAvatarId].COID,
                "link co error"
            );
            require(linkedAvatarId != avatarId, "link to yourself");
            if (
                blockCoordinate.distance(
                    avatarNoumenon[linkedAvatarId].blockCoordinatInt
                ) > 3
            ) {
                revert linkBlockError();
            }
        } else if (collectionMap[avatarNoumenon[avatarId].COID] > 0) {
            if (
                !(avatarNoumenon[avatarId].blockCoordinatInt > 0 &&
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
