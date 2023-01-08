// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/Structs.sol";

interface IMap {
    function getBlocksAvatars(
        Block[] memory blocks
    ) external view returns (uint256[] memory);

    function avatarMove(Block memory blockFrom, Block memory blockTo) external;

    function avatarSet(uint256 avatarId, Block memory blockTo) external;

    function getBlockAvatar(
        Block memory block_
    ) external view returns (uint256);

    function getBlockAttackRangeAvatars(
        Block memory block_
    ) external view returns (uint256[] memory);

    function getBlockSpheres(
        Block memory block_
    ) external view returns (Block[] memory);
}
