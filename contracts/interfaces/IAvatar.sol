// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

struct AvatarData {
    uint256 x;
    uint256 y;
    address cContract;
    uint256 tokenId;
}

interface IAvatar is IERC721Upgradeable {
    function getAvatarOccupiedBlock(uint256 avatarId) external view returns (uint256, uint256);

    function getAvatarSphereBlocks(uint256 avatarId) external view returns (uint256[] memory, uint256[] memory);

    function moveTo(uint256 avatarId, uint256 x, uint256 y) external;

    function jumpIn(address nftcontract, uint256 tokeId) external returns (uint256);

    function claimEnergy(uint256 avatarId) external;
}
