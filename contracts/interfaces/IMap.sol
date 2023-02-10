// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMap {
    function getBlocksAvatars(
        uint32[] memory blockCoordinates
    ) external view returns (uint256[] memory);

    function getBlocksCOIDs(
        uint32[] memory blockCoordinates
    ) external view returns (uint256[] memory);

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 blockCoordinate,
        uint32 PassId,
        uint256 BombUsed
    ) external;

    function avatarRemove(
        uint256 avatarId,
        uint256 COID,
        uint32 blockCoordinate
    ) external;

    function getBlockAvatar(
        uint32 blockCoordinate
    ) external view returns (uint256);

    function getBlockPassId(
        uint32 blockCoordinate
    ) external view returns (uint32);
}
