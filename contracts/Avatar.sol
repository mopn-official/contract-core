// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAvatar.sol";
import "./interfaces/IMap.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Avatar is ERC721Upgradeable {
    mapping(uint256 => AvatarData) public AvatarNoumenon;

    IMap public Map;

    function initialize(address mapContract_) public initializer {
        Map = IMap(mapContract_);
    }

    function getAvatarOccupiedBlock(uint256 avatarId) public view returns (IMap.Block memory) {
        return IMap.Block(AvatarNoumenon[avatarId].x, AvatarNoumenon[avatarId].y);
    }

    function getAvatarSphereBlocks(uint256 avatarId) public view returns (IMap.Block[] memory) {
        return Map.getBlockSphere(getAvatarOccupiedBlock(avatarId));
    }

    function moveTo(uint256 avatarId, uint256 x, uint256 y) public {}

    function jumpIn(address nftcontract, uint256 tokeId) public returns (uint256) {}

    function claimEnergy(uint256 avatarId) public {}
}
