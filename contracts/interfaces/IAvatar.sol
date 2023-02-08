// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAvatar is IERC721 {
    function getAvatarOccupiedBlock(
        uint256 avatarId
    ) external view returns (uint32);

    function getAvatarCOID(uint256 avatarId) external view returns (uint256);

    function ownerOf(uint256 avatarId) external view returns (address);
}
