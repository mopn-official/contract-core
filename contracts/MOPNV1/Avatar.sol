// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAvatar.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Avatar is ERC721Upgradeable, IAvatar {
    mapping(uint256 => AvatarData) public AvatarNoumenon;

    address public mapContract;

    function initialize(address mapContract_) public initializer {
        mapContract = mapContract_;
    }

    function getAvatarOccupiedBlock(uint256 avatarId) external view override returns (uint256, uint256) {}

    function getAvatarSphereBlocks(uint256 avatarId) public view returns (uint256[] memory, uint256[] memory) {}

    function moveTo(uint256 avatarId, uint256 x, uint256 y) public {}

    function jumpIn(address nftcontract, uint256 tokeId) public returns (uint256) {}

    function claimEnergy(uint256 avatarId) public {}
}
