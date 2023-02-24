// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IAvatar.sol";
import "./interfaces/IGovernance.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error TileHasEnemy();
error LandIdOverflow();

/// @title The M(Map) of MOPN
/// core contract for MOPN records all avatars on map
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract Map is Ownable {
    using TileMath for uint32;

    // Tile => avatarId * 10 ** 16 + COID * 10 ** 6 + MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    /**
     * @notice This event emit when an anvatar occupied a tile
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId MOPN Land Id
     * @param tileCoordinate tile coordinate
     */
    event AvatarSet(
        uint256 indexed avatarId,
        uint256 indexed COID,
        uint32 indexed LandId,
        uint32 tileCoordinate
    );

    /**
     * @notice This event emit when an anvatar left a tile
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId MOPN Land Id
     * @param tileCoordinate tile coordinate
     */
    event AvatarRemove(
        uint256 indexed avatarId,
        uint256 indexed COID,
        uint32 indexed LandId,
        uint32 tileCoordinate
    );

    /**
     * @notice get the avatar Id who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileAvatar(
        uint32 tileCoordinate
    ) public view returns (uint256) {
        return tiles[tileCoordinate] / 10 ** 16;
    }

    /**
     * @notice get the coid of the avatar who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileCOID(uint32 tileCoordinate) public view returns (uint256) {
        return (tiles[tileCoordinate] % 10 ** 16) / 10 ** 6;
    }

    /**
     * @notice get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)
     * @param tileCoordinate tile coordinate
     */
    function getTileLandId(uint32 tileCoordinate) public view returns (uint32) {
        return uint32(tiles[tileCoordinate] % 10 ** 6);
    }

    /**
     * @notice batch call for {getTileAvatar}
     * @param tileCoordinates tile coordinate
     */
    function getTilesAvatars(
        uint32[] memory tileCoordinates
    ) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](tileCoordinates.length);
        for (uint256 i = 0; i < tileCoordinates.length; i++) {
            avatarIds[i] = tiles[tileCoordinates[i]] / 10 ** 16;
        }
        return avatarIds;
    }

    IAvatar private Avatar;
    IGovernance private Governance;

    function setGovernanceContract(
        address governanceContract_
    ) public onlyOwner {
        Governance = IGovernance(governanceContract_);
        Avatar = IAvatar(Governance.avatarContract());
    }

    /**
     * @notice avatar id occupied a tile
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param tileCoordinate tile coordinate
     * @param LandId MOPN Land Id
     * @param BombUsed avatar bomb used history number
     * @dev can only called by avatar contract
     */
    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate,
        uint32 LandId,
        uint256 BombUsed
    ) public onlyAvatar {
        require(getTileAvatar(tileCoordinate) == 0, "dst Occupied");

        if (LandId < 1 || LandId > 10981) {
            revert LandIdOverflow();
        }

        if (getTileLandId(tileCoordinate) != LandId) {
            require(
                tileCoordinate.distance(LandId.LandCenterTile()) < 6,
                "LandId error"
            );
        }

        emit AvatarSet(avatarId, COID, LandId, tileCoordinate);

        uint256 TileEAW = tileCoordinate.getTileEAW() + BombUsed;

        tiles[tileCoordinate] = avatarId * 10 ** 16 + COID * 10 ** 6 + LandId;
        tileCoordinate = tileCoordinate.neighbor(4);

        for (uint256 i = 0; i < 18; i++) {
            uint256 tileCOID = getTileCOID(tileCoordinate);
            if (tileCOID > 0 && tileCOID != COID) {
                revert TileHasEnemy();
            }

            if (i == 5) {
                tileCoordinate = tileCoordinate.neighbor(4).neighbor(5);
            } else if (i < 5) {
                tileCoordinate = tileCoordinate.neighbor(i);
            } else {
                tileCoordinate = tileCoordinate.neighbor((i - 6) / 2);
            }
        }

        Governance.addEAW(avatarId, COID, LandId, TileEAW);
    }

    /**
     * @notice avatar id left a tile
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param tileCoordinate tile coordinate
     * @dev can only called by avatar contract
     */
    function avatarRemove(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate
    ) public onlyAvatar {
        uint32 LandId = getTileLandId(tileCoordinate);
        tiles[tileCoordinate] = LandId;
        Governance.subEAW(avatarId, COID, LandId);

        emit AvatarRemove(avatarId, COID, LandId, tileCoordinate);
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

    modifier onlyAvatar() {
        require(msg.sender == address(Avatar), "not allowed");
        _;
    }
}
