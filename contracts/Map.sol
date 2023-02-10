// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPN.sol";
import "./libraries/BlockMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Map is Ownable {
    using BlockMath for uint32;

    // Block => avatarId
    mapping(uint32 => uint256) public blocks;

    uint256[3] BEPSs = [1, 5, 15];

    event AvatarSet(
        uint256 indexed avatarId,
        uint256 indexed COID,
        uint32 indexed PassId,
        uint32 blockCoordinate
    );

    event AvatarRemove(
        uint256 indexed avatarId,
        uint256 indexed COID,
        uint32 indexed PassId,
        uint32 blockCoordinate
    );

    function getBlockAvatar(
        uint32 blockCoordinate
    ) public view returns (uint256) {
        return blocks[blockCoordinate] / 1000000;
    }

    function getBlockPassId(
        uint32 blockCoordinate
    ) public view returns (uint32) {
        return uint32(blocks[blockCoordinate] % 1000000);
    }

    function getBlocksAvatars(
        uint32[] memory blockcoordinates
    ) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](blockcoordinates.length);
        for (uint256 i = 0; i < blockcoordinates.length; i++) {
            avatarIds[i] = blocks[blockcoordinates[i]] / 1000000;
        }
        return avatarIds;
    }

    IAvatar public Avatar;
    IGovernance public Governance;

    function setGovernanceContract(
        address governanceContract_
    ) public onlyOwner {
        Governance = IGovernance(governanceContract_);
        Avatar = IAvatar(Governance.avatarContract());
    }

    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 blockCoordinate,
        uint32 PassId,
        uint256 BombUsed
    ) public onlyAvatar {
        require(Map.getBlockAvatar(blockCoordinate) == 0, "dst Occupied");

        if (PassId < 1 || PassId > 10981) {
            revert PassIdOverflow();
        }

        if (getBlockPassId(blockCoordinate) != PassId) {
            require(
                blockCoordinate.distance(PassId.PassCenterBlock()) < 6,
                "PassId error"
            );
        }

        emit AvatarSet(avatarId, COID, PassId, blockCoordinate);

        uint256 BEPS = blockCoordinate.getBlockBEPS() + BombUsed;

        blocks[blockCoordinate] = avatarId * 1000000 + PassId;
        blockCoordinate = blockCoordinate.neighbor(4);

        for (uint256 i = 0; i < 18; i++) {
            uint256 coAvatarId = getBlockAvatar(blockCoordinate);
            if (coAvatarId > 0 && Avatar.getAvatarCOID(coAvatarId) != COID) {
                revert BlockHasEnemy();
            }

            if (i == 5) {
                blockCoordinate = blockCoordinate.neighbor(4);
            } else if (i < 5) {
                blockCoordinate = blockCoordinate.neighbor(i);
            } else {
                blockCoordinate = blockCoordinate.neighbor((i - 6) / 2);
            }
        }

        Governance.addBEPS(avatarId, COID, PassId, BEPS);
    }

    function avatarRemove(
        uint256 avatarId,
        uint256 COID,
        uint32 blockCoordinate
    ) public onlyAvatar {
        uint32 PassId = getBlockPassId(blockCoordinate);
        blocks[blockCoordinate] = PassId;
        Governance.subBEPS(avatarId, COID, PassId);

        emit AvatarRemove(avatarId, COID, PassId, blockCoordinate);
    }

    modifier checkPassId(uint32 blockCoordinate, uint32 PassId) {
        if (getBlockPassId(blockCoordinate) != PassId) {
            require(
                blockCoordinate.distance(PassId.PassCenterBlock()) < 6,
                "PassId error"
            );
        }
        _;
    }

    modifier onlyAvatar() {
        require(msg.sender == address(Avatar), "not allowed");
        _;
    }
}
