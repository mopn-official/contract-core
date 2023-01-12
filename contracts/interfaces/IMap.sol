// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/Structs.sol";

interface IMap {
    function getBlocksAvatars(
        Block[] memory blocks
    ) external view returns (uint256[] memory);

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        Block memory blockTo
    ) external;

    function avatarRemove(Block memory block_, uint256 COID) external;

    function getBlockAvatar(
        Block memory block_
    ) external view returns (uint256);
}
