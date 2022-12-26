// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAvatar.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Map is Initializable {
    // x => y => avatarId
    mapping(uint256 => mapping(uint256 => uint256)) public blocks;

    IAvatar public Avatar;

    function initialize(address avatarContract_) public initializer {
        Avatar = IAvatar(avatarContract_);
    }

    function getBlocksAvatars(uint256[] memory xs, uint256[] memory ys) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](xs.length);
        for (uint256 i = 0; i < xs.length; i++) {
            avatarIds[i] = blocks[xs[i]][ys[i]];
        }
        return avatarIds;
    }
}
