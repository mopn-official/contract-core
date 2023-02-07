// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAvatar is IERC721 {
    function getAvatarOccupiedBlock(
        uint256 avatarId
    ) external view returns (uint256, uint256);

    function getAvatarSphereBlocks(
        uint256 avatarId
    ) external view returns (uint256[] memory, uint256[] memory);

    function getAvatarCOID(uint256 avatarId) external view returns (uint256);

    function moveTo(uint256 avatarId, uint256 x, uint256 y) external;

    function ownerOf(uint256 avatarId) external view returns (address);
}
