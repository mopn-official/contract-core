// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMap {
    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate,
        uint32 LandId
    ) external;

    function avatarRemove(
        uint32 tileCoordinate,
        uint256 excludeAvatarId
    ) external returns (uint256);

    function getTileAvatar(
        uint32 tileCoordinate
    ) external view returns (uint256);

    function getTileCOID(uint32 tileCoordinate) external view returns (uint256);

    function getTileLandId(
        uint32 tileCoordinate
    ) external view returns (uint32);
}
