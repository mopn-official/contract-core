// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/ILand.sol";
import "./interfaces/IMiningData.sol";
import "./interfaces/IGovernance.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title The M(Map) of MOPN
/// core contract for MOPN records all avatars on map
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract Map is Ownable, Multicall {
    using TileMath for uint32;

    // Tile => uint64 avatarId + uint64 COID + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    IGovernance public governance;

    constructor(address governance_) {
        governance = IGovernance(governance_);
    }

    /**
     * @notice get the avatar Id who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileAvatar(
        uint32 tileCoordinate
    ) public view returns (uint256) {
        return uint64(tiles[tileCoordinate] >> 192);
    }

    /**
     * @notice get the coid of the avatar who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileCOID(uint32 tileCoordinate) public view returns (uint256) {
        return uint64(tiles[tileCoordinate] >> 128);
    }

    /**
     * @notice get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)
     * @param tileCoordinate tile coordinate
     */
    function getTileLandId(uint32 tileCoordinate) public view returns (uint32) {
        return uint32(tiles[tileCoordinate]);
    }

    /**
     * @notice avatar id occupied a tile
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param tileCoordinate tile coordinate
     * @param LandId MOPN Land Id
     * @dev can only called by avatar contract
     */
    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate,
        uint32 LandId
    ) public onlyAvatar {
        require(getTileAvatar(tileCoordinate) == 0, "dst Occupied");

        if (LandId == 0 || getTileLandId(tileCoordinate) != LandId) {
            require(
                LandId < ILand(governance.landContract()).MAX_SUPPLY(),
                "landId overflow"
            );
            require(
                tileCoordinate.distance(LandId.LandCenterTile()) < 6,
                "LandId error"
            );
            require(
                ILand(governance.landContract()).nextTokenId() > LandId,
                "Land Not Open"
            );
        }

        uint256 TilePoint = tileCoordinate.getTileNFTPoint() +
            IAvatar(governance.avatarContract()).getAvatarBombUsed(avatarId);

        tiles[tileCoordinate] =
            (avatarId << 192) |
            (COID << 128) |
            uint256(LandId);
        tileCoordinate = tileCoordinate.neighbor(4);

        for (uint256 i = 0; i < 18; i++) {
            uint256 tileCOID = getTileCOID(tileCoordinate);
            require(tileCOID == 0 || tileCOID == COID, "tile has enemy");

            if (i == 5) {
                tileCoordinate = tileCoordinate.neighbor(4).neighbor(5);
            } else if (i < 5) {
                tileCoordinate = tileCoordinate.neighbor(i);
            } else {
                tileCoordinate = tileCoordinate.neighbor((i - 6) / 2);
            }
        }

        IMiningData(governance.miningDataContract()).addNFTPoint(
            avatarId,
            COID,
            TilePoint
        );
    }

    /**
     * @notice avatar id left a tile
     * @param tileCoordinate tile coordinate
     * @dev can only called by avatar contract
     */
    function avatarRemove(
        uint32 tileCoordinate,
        uint256 excludeAvatarId
    ) public onlyAvatar returns (uint256 avatarId) {
        avatarId = getTileAvatar(tileCoordinate);
        if (avatarId > 0 && avatarId != excludeAvatarId) {
            uint32 LandId = getTileLandId(tileCoordinate);
            IMiningData(governance.miningDataContract()).subNFTPoint(
                avatarId,
                getTileCOID(tileCoordinate)
            );
            tiles[tileCoordinate] = LandId;
        } else {
            avatarId = 0;
        }
    }

    modifier checkLandId(uint32 tileCoordinate, uint32 LandId) {
        if (getTileLandId(tileCoordinate) != LandId) {
            require(
                tileCoordinate.distance(LandId.LandCenterTile()) < 6,
                "LandId error"
            );
        }
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "not allowed");
        _;
    }

    modifier onlyAvatar() {
        require(msg.sender == governance.avatarContract(), "not allowed");
        _;
    }
}
