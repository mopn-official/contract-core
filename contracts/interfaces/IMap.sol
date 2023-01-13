// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/Structs.sol";

interface IMap {
    function getBlocksAvatars(
        uint64[] memory blocks
    ) external view returns (uint256[] memory);

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint64 blockTo,
        uint64[] memory blockSphere,
        uint8[] memory blockLevels
    ) external;

    function avatarRemove(uint64 blockcoordinate) external;

    function getBlockAvatar(uint64 block_) external view returns (uint256);
}
