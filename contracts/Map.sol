// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPN.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Map is Ownable {
    using TileMath for uint32;

    // Tile => avatarId
    mapping(uint32 => uint256) public tiles;

    event AvatarSet(
        uint256 indexed avatarId,
        uint256 indexed COID,
        uint32 indexed PassId,
        uint32 tileCoordinate
    );

    event AvatarRemove(
        uint256 indexed avatarId,
        uint256 indexed COID,
        uint32 indexed PassId,
        uint32 tileCoordinate
    );

    function getTileAvatar(
        uint32 tileCoordinate
    ) public view returns (uint256) {
        return tiles[tileCoordinate] / 1000000;
    }

    function getTilePassId(uint32 tileCoordinate) public view returns (uint32) {
        return uint32(tiles[tileCoordinate] % 1000000);
    }

    function getTilesAvatars(
        uint32[] memory tileCoordinates
    ) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](tileCoordinates.length);
        for (uint256 i = 0; i < tileCoordinates.length; i++) {
            avatarIds[i] = tiles[tileCoordinates[i]] / 1000000;
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
        uint32 tileCoordinate,
        uint32 PassId,
        uint256 BombUsed
    ) public onlyAvatar {
        require(getTileAvatar(tileCoordinate) == 0, "dst Occupied");

        if (PassId < 1 || PassId > 10981) {
            revert PassIdOverflow();
        }

        if (getTilePassId(tileCoordinate) != PassId) {
            require(
                tileCoordinate.distance(PassId.PassCenterTile()) < 6,
                "PassId error"
            );
        }

        emit AvatarSet(avatarId, COID, PassId, tileCoordinate);

        uint256 TileEAW = tileCoordinate.getTileEAW() + BombUsed;

        tiles[tileCoordinate] = avatarId * 1000000 + PassId;
        tileCoordinate = tileCoordinate.neighbor(4);

        for (uint256 i = 0; i < 18; i++) {
            uint256 coAvatarId = getTileAvatar(tileCoordinate);
            if (coAvatarId > 0 && Avatar.getAvatarCOID(coAvatarId) != COID) {
                revert TileHasEnemy();
            }

            if (i == 5) {
                tileCoordinate = tileCoordinate.neighbor(4);
            } else if (i < 5) {
                tileCoordinate = tileCoordinate.neighbor(i);
            } else {
                tileCoordinate = tileCoordinate.neighbor((i - 6) / 2);
            }
        }

        Governance.addEAW(avatarId, COID, PassId, TileEAW);
    }

    function avatarRemove(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate
    ) public onlyAvatar {
        uint32 PassId = getTilePassId(tileCoordinate);
        tiles[tileCoordinate] = PassId;
        Governance.subEAW(avatarId, COID, PassId);

        emit AvatarRemove(avatarId, COID, PassId, tileCoordinate);
    }

    modifier checkPassId(uint32 tileCoordinate, uint32 PassId) {
        if (getTilePassId(tileCoordinate) != PassId) {
            require(
                tileCoordinate.distance(PassId.PassCenterTile()) < 6,
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
