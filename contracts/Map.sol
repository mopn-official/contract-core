// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/ILand.sol";
import "./interfaces/IGovernance.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title The M(Map) of MOPN
/// core contract for MOPN records all avatars on map
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract Map is Ownable, Multicall {
    using TileMath for uint32;

    // Tile => uint64 avatarId + uint64 COID + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    uint256 public constant MTProducePerSecond = 50000000000;

    uint256 public constant MTProduceReduceInterval = 600000;

    uint256 public MTProduceStartTimestamp;

    /// @notice uint64 PerMTAWMinted + uint64 LastPerMTAWMintedCalcTimestamp + uint64 TotalMTAWs
    uint256 public MTProduceData;

    /// @notice uint64 MT Inbox + uint64 Total Minted MT + uint64 PerMTAWMinted + uint64 TotalMTAWs
    mapping(uint256 => uint256) public AvatarMTs;

    mapping(uint256 => uint256) public CollectionMTs;

    mapping(uint32 => uint256) public LandHolderMTs;

    event AvatarMTMinted(uint256 indexed avatarId, uint256 amount);

    event CollectionMTMinted(uint256 indexed COID, uint256 amount);

    event LandHolderMTMinted(uint32 indexed LandId, uint256 amount);

    constructor(uint256 MTProduceStartTimestamp_) {
        MTProduceStartTimestamp = MTProduceStartTimestamp_;
    }

    /**
     * @notice get the avatar Id who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileAvatar(
        uint32 tileCoordinate
    ) public view returns (uint256) {
        return uint64(tiles[tileCoordinate] >> 192);
    }

    /**
     * @notice get the coid of the avatar who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileCOID(uint32 tileCoordinate) public view returns (uint256) {
        return uint64(tiles[tileCoordinate] >> 128);
    }

    /**
     * @notice get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)
     * @param tileCoordinate tile coordinate
     */
    function getTileLandId(uint32 tileCoordinate) public view returns (uint32) {
        return uint32(tiles[tileCoordinate]);
    }

    address public governanceContract;

    function setGovernanceContract(
        address governanceContract_
    ) public onlyOwner {
        governanceContract = governanceContract_;
    }

    /**
     * @notice avatar id occupied a tile
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param tileCoordinate tile coordinate
     * @param LandId MOPN Land Id
     * @param BombUsed avatar bomb used history number
     * @dev can only called by avatar contract
     */
    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate,
        uint32 LandId,
        uint256 BombUsed
    ) public onlyAvatar {
        require(getTileAvatar(tileCoordinate) == 0, "dst Occupied");

        if (getTileLandId(tileCoordinate) != LandId) {
            require(
                LandId <
                    ILand(IGovernance(governanceContract).landContract())
                        .MAX_SUPPLY(),
                "landId overflow"
            );
            require(
                tileCoordinate.distance(LandId.LandCenterTile()) < 6,
                "LandId error"
            );
            require(
                ILand(IGovernance(governanceContract).landContract())
                    .nextTokenId() > LandId,
                "Land Not Open"
            );
        }

        uint256 TileMTAW = tileCoordinate.getTileMTAW() + BombUsed;

        tiles[tileCoordinate] =
            (avatarId << 192) |
            (COID << 128) |
            uint256(LandId);
        tileCoordinate = tileCoordinate.neighbor(4);

        for (uint256 i = 0; i < 18; i++) {
            uint256 tileCOID = getTileCOID(tileCoordinate);
            require(tileCOID == 0 || tileCOID == COID, "tile has enemy");

            if (i == 5) {
                tileCoordinate = tileCoordinate.neighbor(4).neighbor(5);
            } else if (i < 5) {
                tileCoordinate = tileCoordinate.neighbor(i);
            } else {
                tileCoordinate = tileCoordinate.neighbor((i - 6) / 2);
            }
        }

        _addMTAW(avatarId, COID, LandId, TileMTAW);
    }

    /**
     * @notice avatar id left a tile
     * @param tileCoordinate tile coordinate
     * @dev can only called by avatar contract
     */
    function avatarRemove(
        uint32 tileCoordinate,
        uint256 excludeAvatarId
    ) public onlyAvatar returns (uint256 avatarId) {
        avatarId = getTileAvatar(tileCoordinate);
        if (avatarId > 0 && avatarId != excludeAvatarId) {
            uint32 LandId = getTileLandId(tileCoordinate);
            _subMTAW(avatarId, getTileCOID(tileCoordinate), LandId);
            tiles[tileCoordinate] = LandId;
        } else {
            avatarId = 0;
        }
    }

    /**
     * @notice get settled Per MT Allocation Weight minted mopn token number
     */
    function getPerMTAWMinted() public view returns (uint256) {
        return uint64(MTProduceData >> 128);
    }

    /**
     * @notice get last per mopn token allocation weight minted settlement timestamp
     */
    function getLastPerMTAWMintedCalcTimestamp() public view returns (uint256) {
        return uint64(MTProduceData >> 64);
    }

    /**
     * @notice get total mopn token allocation weights
     */
    function getTotalMTAWs() public view returns (uint256) {
        return uint64(MTProduceData);
    }

    /**
     * get current mt produce per second
     * @param reduceTimes reduce times
     */
    function currentMTPPS(
        uint256 reduceTimes
    ) public pure returns (uint256 MTPPB) {
        int128 reducePercentage = ABDKMath64x64.divu(997, 1000);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, MTProducePerSecond);
    }

    function currentMTPPS() public view returns (uint256 MTPPB) {
        if (MTProduceStartTimestamp > block.timestamp) {
            return 0;
        }
        uint256 reduceTimes = (block.timestamp - MTProduceStartTimestamp) /
            MTProduceReduceInterval;
        return currentMTPPS(reduceTimes);
    }

    /**
     * @notice settle per mopn token allocation weight minted mopn token
     */
    function settlePerMTAWMinted() public {
        if (block.timestamp > getLastPerMTAWMintedCalcTimestamp()) {
            uint256 PerMTAWMinted = calcPerMTAWMinted();
            MTProduceData =
                (PerMTAWMinted << 128) |
                (block.timestamp << 64) |
                getTotalMTAWs();
        }
    }

    function calcPerMTAWMinted() public view returns (uint256) {
        if (MTProduceStartTimestamp > block.timestamp) {
            return 0;
        }
        uint256 TotalMTAWs = getTotalMTAWs();
        uint256 PerMTAWMinted = getPerMTAWMinted();
        if (TotalMTAWs > 0) {
            uint256 LastPerMTAWMintedCalcTimestamp = getLastPerMTAWMintedCalcTimestamp();
            uint256 reduceTimes = (LastPerMTAWMintedCalcTimestamp -
                MTProduceStartTimestamp) / MTProduceReduceInterval;
            uint256 nextReduceTimestamp = MTProduceStartTimestamp +
                MTProduceReduceInterval +
                reduceTimes *
                MTProduceReduceInterval;

            while (true) {
                if (block.timestamp > nextReduceTimestamp) {
                    PerMTAWMinted +=
                        ((nextReduceTimestamp -
                            LastPerMTAWMintedCalcTimestamp) *
                            currentMTPPS(reduceTimes)) /
                        TotalMTAWs;
                    LastPerMTAWMintedCalcTimestamp = nextReduceTimestamp;
                    reduceTimes++;
                    nextReduceTimestamp += MTProduceReduceInterval;
                } else {
                    PerMTAWMinted +=
                        ((block.timestamp - LastPerMTAWMintedCalcTimestamp) *
                            currentMTPPS(reduceTimes)) /
                        TotalMTAWs;
                    break;
                }
            }
        }
        return PerMTAWMinted;
    }

    /**
     * @notice get avatar settled unclaimed minted mopn token
     * @param avatarId avatar Id
     */
    function getAvatarSettledInboxMT(
        uint256 avatarId
    ) public view returns (uint256) {
        return uint64(AvatarMTs[avatarId] >> 192);
    }

    function getAvatarTotalMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return uint64(AvatarMTs[avatarId] >> 128);
    }

    /**
     * @notice get avatar settled per mopn token allocation weight minted mopn token number
     * @param avatarId avatar Id
     */
    function getAvatarPerMTAWMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return uint64(AvatarMTs[avatarId] >> 64);
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param avatarId avatar Id
     */
    function getAvatarMTAW(uint256 avatarId) public view returns (uint256) {
        return uint64(AvatarMTs[avatarId]);
    }

    /**
     * @notice mint avatar mopn token
     * @param avatarId avatar Id
     */
    function mintAvatarMT(uint256 avatarId) public {
        uint256 AvatarMTAW = getAvatarMTAW(avatarId);
        uint256 AvatarPerMTAWMinted = getAvatarPerMTAWMinted(avatarId);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        if (AvatarPerMTAWMinted < PerMTAWMinted) {
            if (AvatarMTAW > 0) {
                uint256 amount = ((((PerMTAWMinted - AvatarPerMTAWMinted) *
                    AvatarMTAW) * 90) / 100);
                AvatarMTs[avatarId] +=
                    (amount << 192) |
                    ((PerMTAWMinted - AvatarPerMTAWMinted) << 64);
                emit AvatarMTMinted(avatarId, amount);
            } else {
                AvatarMTs[avatarId] +=
                    (PerMTAWMinted - AvatarPerMTAWMinted) <<
                    64;
            }
        }
    }

    function claimAvatarSettledIndexMT(
        uint256 avatarId
    ) public onlyGovernance returns (uint256 amount) {
        amount = getAvatarSettledInboxMT(avatarId);
        if (amount > 0) {
            AvatarMTs[avatarId] -= amount << 192;
            AvatarMTs[avatarId] += amount << 128;
        }
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param avatarId avatar Id
     */
    function getAvatarInboxMT(
        uint256 avatarId
    ) public view returns (uint256 inbox) {
        inbox = getAvatarSettledInboxMT(avatarId);
        uint256 PerMTAWMinted = calcPerMTAWMinted();
        uint256 AvatarPerMTAWMinted = getAvatarPerMTAWMinted(avatarId);
        uint256 AvatarMTAW = getAvatarMTAW(avatarId);

        if (AvatarPerMTAWMinted < PerMTAWMinted && AvatarMTAW > 0) {
            inbox +=
                (((PerMTAWMinted - AvatarPerMTAWMinted) * AvatarMTAW) * 90) /
                100;
        }
    }

    /**
     * @notice get collection settled minted unclaimed mopn token
     * @param COID collection Id
     */
    function getCollectionSettledInboxMT(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(CollectionMTs[COID] >> 192);
    }

    function getCollectionTotalMinted(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(CollectionMTs[COID] >> 128);
    }

    /**
     * @notice get collection settled per mopn token allocation weight minted mopn token number
     * @param COID collection Id
     */
    function getCollectionPerMTAWMinted(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(CollectionMTs[COID] >> 64);
    }

    /**
     * @notice get collection on map mining mopn token allocation weight
     * @param COID collection Id
     */
    function getCollectionMTAW(uint256 COID) public view returns (uint256) {
        return uint64(CollectionMTs[COID]);
    }

    /**
     * @notice mint collection mopn token
     * @param COID collection Id
     */
    function mintCollectionMT(uint256 COID) public {
        uint256 CollectionMTAW = getCollectionMTAW(COID);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        uint256 CollectionPerMTAWMinted = getCollectionPerMTAWMinted(COID);
        if (CollectionPerMTAWMinted < PerMTAWMinted) {
            if (CollectionMTAW > 0) {
                uint256 amount = ((((PerMTAWMinted - CollectionPerMTAWMinted) *
                    CollectionMTAW) * 5) / 100);
                CollectionMTs[COID] +=
                    (amount << 192) |
                    ((PerMTAWMinted - CollectionPerMTAWMinted) << 64);
                emit CollectionMTMinted(COID, amount);
            } else {
                CollectionMTs[COID] +=
                    (PerMTAWMinted - CollectionPerMTAWMinted) <<
                    64;
            }
        }
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param COID collection Id
     */
    function getCollectionInboxMT(
        uint256 COID
    ) public view returns (uint256 inbox) {
        inbox = getCollectionSettledInboxMT(COID);
        uint256 PerMTAWMinted = calcPerMTAWMinted();
        uint256 CollectionPerMTAWMinted = getCollectionPerMTAWMinted(COID);
        uint256 CollectionMTAW = getCollectionMTAW(COID);

        if (CollectionPerMTAWMinted < PerMTAWMinted && CollectionMTAW > 0) {
            inbox +=
                (((PerMTAWMinted - CollectionPerMTAWMinted) * CollectionMTAW) *
                    5) /
                100;
        }
    }

    /**
     * @notice redeem 1/collectionOnMapNFTNumber of collection unclaimed minted mopn token to a avatar
     * only avatar contract can calls
     * @param avatarId avatar Id
     * @param COID collection Id
     */
    function claimCollectionSettledInboxMT(
        uint256 avatarId,
        uint256 COID
    ) public onlyGovernance returns (uint256 amount) {
        amount = getCollectionSettledInboxMT(COID);
        if (amount > 0) {
            amount =
                amount /
                (IGovernance(governanceContract).getCollectionOnMapNum(COID) +
                    1);
            CollectionMTs[COID] -= amount << 192;
            CollectionMTs[COID] += amount << 128;
            AvatarMTs[avatarId] += amount << 128;
            emit AvatarMTMinted(avatarId, amount);
        }
    }

    /**
     * @notice get Land holder settled minted unclaimed mopn token
     * @param LandId MOPN Land Id
     */
    function getLandHolderSettledInboxMT(
        uint32 LandId
    ) public view returns (uint256) {
        return uint64(LandHolderMTs[LandId] >> 192);
    }

    function getLandHolderTotalMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return uint64(LandHolderMTs[LandId] >> 128);
    }

    /**
     * @notice get Land holder settled per mopn token allocation weight minted mopn token number
     * @param LandId MOPN Land Id
     */
    function getLandHolderPerMTAWMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return uint64(LandHolderMTs[LandId] >> 64);
    }

    /**
     * @notice get Land holder on map mining mopn token allocation weight
     * @param LandId MOPN Land Id
     */
    function getLandHolderMTAW(uint32 LandId) public view returns (uint256) {
        return uint64(LandHolderMTs[LandId]);
    }

    /**
     * @notice mint Land holder mopn token
     * @param LandId MOPN Land Id
     */
    function mintLandHolderMT(uint32 LandId) public {
        uint256 LandHolderMTAW = getLandHolderMTAW(LandId);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        uint256 LandHolderPerMTAWMinted = getLandHolderPerMTAWMinted(LandId);
        if (LandHolderPerMTAWMinted < PerMTAWMinted) {
            if (LandHolderMTAW > 0) {
                uint256 amount = (((PerMTAWMinted - LandHolderPerMTAWMinted) *
                    LandHolderMTAW) * 5) / 100;
                LandHolderMTs[LandId] +=
                    (amount << 192) |
                    ((PerMTAWMinted - LandHolderPerMTAWMinted) << 64);
                emit LandHolderMTMinted(LandId, amount);
            } else {
                LandHolderMTs[LandId] +=
                    (PerMTAWMinted - LandHolderPerMTAWMinted) <<
                    64;
            }
        }
    }

    function claimLandHolderSettledIndexMT(
        uint32 LandId
    ) public onlyGovernance returns (uint256 amount) {
        amount = getLandHolderSettledInboxMT(LandId);
        if (amount > 0) {
            LandHolderMTs[LandId] -= amount << 192;
            LandHolderMTs[LandId] += amount << 128;
        }
    }

    /**
     * @notice get Land holder realtime unclaimed minted mopn token
     * @param LandId MOPN Land Id
     */
    function getLandHolderInboxMT(
        uint32 LandId
    ) public view returns (uint256 inbox) {
        inbox = getLandHolderSettledInboxMT(LandId);
        uint256 PerMTAWMinted = calcPerMTAWMinted();
        uint256 LandHolderPerMTAWMinted = getLandHolderPerMTAWMinted(LandId);
        uint256 LandHolderMTAW = getLandHolderMTAW(LandId);

        if (LandHolderPerMTAWMinted < PerMTAWMinted && LandHolderMTAW > 0) {
            inbox +=
                (((PerMTAWMinted - LandHolderPerMTAWMinted) * LandHolderMTAW) *
                    5) /
                100;
        }
    }

    function addMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) public onlyAvatar {
        _addMTAW(avatarId, COID, LandId, amount);
    }

    /**
     * add on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId mopn Land Id
     * @param amount EAW amount
     */
    function _addMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) internal {
        settlePerMTAWMinted();
        MTProduceData += amount;
        mintAvatarMT(avatarId);
        AvatarMTs[avatarId] += amount;
        mintCollectionMT(COID);
        CollectionMTs[COID] += amount;
        mintLandHolderMT(LandId);
        LandHolderMTs[LandId] += amount;
    }

    /**
     * substruct on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId mopn Land Id
     */
    function _subMTAW(uint256 avatarId, uint256 COID, uint32 LandId) internal {
        settlePerMTAWMinted();
        uint256 amount = getAvatarMTAW(avatarId);
        MTProduceData -= amount;
        mintAvatarMT(avatarId);
        AvatarMTs[avatarId] -= amount;
        mintCollectionMT(COID);
        CollectionMTs[COID] -= amount;
        mintLandHolderMT(LandId);
        LandHolderMTs[LandId] -= amount;
    }

    modifier checkLandId(uint32 tileCoordinate, uint32 LandId) {
        if (getTileLandId(tileCoordinate) != LandId) {
            require(
                tileCoordinate.distance(LandId.LandCenterTile()) < 6,
                "LandId error"
            );
        }
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceContract, "not allowed");
        _;
    }

    modifier onlyAvatar() {
        require(
            msg.sender == IGovernance(governanceContract).avatarContract(),
            "not allowed"
        );
        _;
    }
}
