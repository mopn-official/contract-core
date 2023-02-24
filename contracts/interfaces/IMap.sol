// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMap {
    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate,
        uint32 LandId,
        uint256 BombUsed
    ) external;

    function avatarRemove(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate
    ) external;

    function getTileAvatar(
        uint32 tileCoordinate
    ) external view returns (uint256);

    function getTilesAvatars(
        uint32[] memory tileCoordinates
    ) external view returns (uint256[] memory);

    function getTileCOID(uint32 tileCoordinate) external view returns (uint256);

    function getTileLandId(
        uint32 tileCoordinate
    ) external view returns (uint32);
}
