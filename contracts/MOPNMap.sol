// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IERC6551Account.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IMOPNMiningData.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title The M(Map) of MOPN
/// core contract for MOPN records all avatars on map
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract MOPNMap is Ownable, Multicall {
    using TileMath for uint32;

    // Tile => uint160 account + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    IMOPNGovernance public governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    /**
     * @notice get the avatar Id who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileAccount(
        uint32 tileCoordinate
    ) public view returns (address payable) {
        return payable(address(uint160(tiles[tileCoordinate] >> 32)));
    }

    /**
     * @notice get the coid of the avatar who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileCollection(
        uint32 tileCoordinate
    ) public view returns (address collectionAddress) {
        (, collectionAddress, ) = IERC6551Account(
            getTileAccount(tileCoordinate)
        ).token();
    }

    /**
     * @notice get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)
     * @param tileCoordinate tile coordinate
     */
    function getTileLandId(uint32 tileCoordinate) public view returns (uint32) {
        return uint32(tiles[tileCoordinate]);
    }

    /**
     * @notice avatar id occupied a tile
     * @param account avatar Id
     * @param tileCoordinate tile coordinate
     * @param LandId MOPN Land Id
     * @dev can only called by avatar contract
     */
    function accountSet(
        address account,
        uint32 tileCoordinate,
        uint32 LandId
    ) public onlyAvatar returns (uint256) {
        require(getTileAccount(tileCoordinate) == address(0), "dst Occupied");

        if (LandId == 0 || getTileLandId(tileCoordinate) != LandId) {
            require(
                LandId < IMOPNLand(governance.landContract()).MAX_SUPPLY(),
                "landId overflow"
            );
            require(
                tileCoordinate.distance(LandId.LandCenterTile()) < 6,
                "LandId error"
            );
            require(
                IMOPNLand(governance.landContract()).nextTokenId() > LandId,
                "Land Not Open"
            );
        }

        uint256 TilePoint = tileCoordinate.getTileNFTPoint();

        tiles[tileCoordinate] =
            (uint256(uint160(account)) << 32) |
            uint256(LandId);
        tileCoordinate = tileCoordinate.neighbor(4);

        (, address collectionAddress, ) = IERC6551Account(payable(account))
            .token();
        for (uint256 i = 0; i < 18; i++) {
            address tileCollectionAddress = getTileCollection(tileCoordinate);
            require(
                tileCollectionAddress == address(0) ||
                    tileCollectionAddress == collectionAddress,
                "tile has enemy"
            );

            if (i == 5) {
                tileCoordinate = tileCoordinate.neighbor(4).neighbor(5);
            } else if (i < 5) {
                tileCoordinate = tileCoordinate.neighbor(i);
            } else {
                tileCoordinate = tileCoordinate.neighbor((i - 6) / 2);
            }
        }

        return TilePoint;
    }

    /**
     * @notice avatar id left a tile
     * @param tileCoordinate tile coordinate
     * @dev can only called by avatar contract
     */
    function accountRemove(
        uint32 tileCoordinate,
        address excludeAccount
    ) public onlyAvatar returns (address payable account) {
        account = getTileAccount(tileCoordinate);
        if (account != address(0) && account != excludeAccount) {
            uint32 LandId = getTileLandId(tileCoordinate);
            tiles[tileCoordinate] = LandId;
        } else {
            account = payable(address(0));
        }
    }

    modifier onlyAvatar() {
        require(msg.sender == governance.mopnContract(), "not allowed");
        _;
    }
}
