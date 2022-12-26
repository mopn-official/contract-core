// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMap {
    struct Block {
        uint256 x;
        uint256 y;
    }

    function getBlocksAvatars(uint256[] memory xs, uint256[] memory ys) external view returns (uint256[] memory);

    function getBlockAvatar(uint256[] memory xs, uint256[] memory ys) external view returns (uint256[] memory);

    function getBlocksSpheres(uint256[] memory xs, uint256[] memory ys) external view returns (uint256[] memory);

    function getBlockSphere(Block memory) external view returns (Block[] memory);
}
