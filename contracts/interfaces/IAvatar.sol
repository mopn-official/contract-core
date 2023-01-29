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

    function moveTo(uint256 avatarId, uint256 x, uint256 y) external;

    function jumpIn(
        address nftcontract,
        uint256 tokeId
    ) external returns (uint256);

    function claimEnergy(uint256 avatarId) external;

    function addBLER(uint256 avatarId, uint256 amount) external;

    function subBLER(uint256 avatarId, uint256 amount) external;
}
