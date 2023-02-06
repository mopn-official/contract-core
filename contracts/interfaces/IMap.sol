// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/Structs.sol";

interface IMap {
    function getBlocksAvatars(
        uint64[] memory blockCoordinates
    ) external view returns (uint256[] memory);

    function getBlocksCOIDs(
        uint64[] memory blockCoordinates
    ) external view returns (uint256[] memory);

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint64 blockCoordinate,
        uint64 PassId,
        uint256 BombUsed
    ) external;

    function avatarRemove(
        uint256 avatarId,
        uint256 COID,
        uint64 blockCoordinate
    ) external;

    function getBlockAvatar(
        uint64 blockCoordinate
    ) external view returns (uint256);

    function getBlockPassId(
        uint64 blockCoordinate
    ) external view returns (uint64);
}
