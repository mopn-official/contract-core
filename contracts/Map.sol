// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/ILand.sol";
import "./interfaces/IGovernance.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

error TileHasEnemy();
error LandIdOverflow();

/// @title The M(Map) of MOPN
/// core contract for MOPN records all avatars on map
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract Map is Ownable, Multicall {
    using TileMath for uint32;

    // Tile => avatarId * 10 ** 16 + COID * 10 ** 6 + MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    uint256 public constant MTProducePerBlock = 600000000000;

    uint256 public constant MTProduceReduceInterval = 50000;

    uint256 public MTProduceStartBlock;

    /// @notice PerMTAWMinted * 10 ** 24 + LastPerMTAWMintedCalcBlock * 10 ** 12 + TotalMTAWs
    uint256 public MTProduceData;

    /// @notice MT Inbox * 10 ** 52 + Total Minted MT * 10 ** 32 + PerMTAWMinted * 10 ** 12 + TotalMTAWs
    mapping(uint256 => uint256) public AvatarMTs;

    mapping(uint256 => uint256) public CollectionMTs;

    mapping(uint32 => uint256) public LandHolderMTs;

    event AvatarMTMinted(uint256 indexed avatarId, uint256 amount);

    event CollectionMTMinted(uint256 indexed COID, uint256 amount);

    constructor(uint256 MTProduceStartBlock_) {
        MTProduceStartBlock = MTProduceStartBlock_;
    }

    /**
     * @notice get the avatar Id who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileAvatar(
        uint32 tileCoordinate
    ) public view returns (uint256) {
        return tiles[tileCoordinate] / 10 ** 16;
    }

    /**
     * @notice get the coid of the avatar who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileCOID(uint32 tileCoordinate) public view returns (uint256) {
        return (tiles[tileCoordinate] % 10 ** 16) / 10 ** 6;
    }

    /**
     * @notice get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)
     * @param tileCoordinate tile coordinate
     */
    function getTileLandId(uint32 tileCoordinate) public view returns (uint32) {
        return uint32(tiles[tileCoordinate] % 10 ** 6);
    }

    /**
     * @notice batch call for {getTileAvatar}
     * @param tileCoordinates tile coordinate
     */
    function getTilesAvatars(
        uint32[] memory tileCoordinates
    ) public view returns (uint256[] memory) {
        uint256[] memory avatarIds = new uint256[](tileCoordinates.length);
        for (uint256 i = 0; i < tileCoordinates.length; i++) {
            avatarIds[i] = tiles[tileCoordinates[i]] / 10 ** 16;
        }
        return avatarIds;
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

        if (LandId >= 10981) {
            revert LandIdOverflow();
        }

        if (getTileLandId(tileCoordinate) != LandId) {
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

        tiles[tileCoordinate] = avatarId * 10 ** 16 + COID * 10 ** 6 + LandId;
        tileCoordinate = tileCoordinate.neighbor(4);

        for (uint256 i = 0; i < 18; i++) {
            uint256 tileCOID = getTileCOID(tileCoordinate);
            if (tileCOID > 0 && tileCOID != COID) {
                revert TileHasEnemy();
            }

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
        return MTProduceData / 10 ** 24;
    }

    /**
     * @notice get MT last minted settlement block number
     */
    function getLastPerMTAWMintedCalcBlock() public view returns (uint256) {
        return (MTProduceData % 10 ** 24) / 10 ** 12;
    }

    /**
     * @notice get total mopn token allocation weights
     */
    function getTotalMTAWs() public view returns (uint256) {
        return MTProduceData % 10 ** 12;
    }

    uint256[] MTPPBMap = [
        600000000000,
        133576606537,
        29737849684,
        6620468402,
        1473899498,
        328130815,
        73050994,
        16263166,
        3620622,
        806043,
        179440,
        39941,
        8885,
        1970,
        431,
        87,
        13
    ];

    uint256 MTPPBZeroTriger = 8211;

    /**
     * @notice get current mopn token produce per block
     * @param reduceTimes mopn token produce reduce times
     */
    function currentMTPPB(
        uint256 reduceTimes
    ) public view returns (uint256 MTPPB) {
        if (reduceTimes <= MTPPBZeroTriger) {
            uint256 mapKey = reduceTimes / 500;
            if (mapKey >= MTPPBMap.length) {
                mapKey = MTPPBMap.length - 1;
            }
            MTPPB = MTPPBMap[mapKey];
            reduceTimes -= mapKey * 500;
            if (reduceTimes > 0) {
                while (true) {
                    if (reduceTimes > 17) {
                        MTPPB = (MTPPB * 997 ** 17) / (1000 ** 17);
                    } else {
                        MTPPB =
                            (MTPPB * 997 ** reduceTimes) /
                            (1000 ** reduceTimes);
                        break;
                    }
                    reduceTimes -= 17;
                }
            }
        }
    }

    /**
     * @notice settle per mopn token allocation weight mint mopn token
     */
    function settlePerMTAWMinted() public {
        if (block.number > getLastPerMTAWMintedCalcBlock()) {
            uint256 PerMTAWMinted = calcPerMTAWMinted();
            MTProduceData =
                PerMTAWMinted *
                10 ** 24 +
                block.number *
                10 ** 12 +
                getTotalMTAWs();
        }
    }

    function calcPerMTAWMinted() public view returns (uint256) {
        uint256 TotalMTAWs = getTotalMTAWs();
        uint256 PerMTAWMinted = getPerMTAWMinted();
        if (TotalMTAWs > 0) {
            uint256 LastPerMTAWMintedCalcBlock = getLastPerMTAWMintedCalcBlock();
            uint256 reduceTimes = (LastPerMTAWMintedCalcBlock -
                MTProduceStartBlock) / MTProduceReduceInterval;
            uint256 nextReduceBlock = MTProduceStartBlock +
                MTProduceReduceInterval +
                reduceTimes *
                MTProduceReduceInterval;

            while (true) {
                if (block.number > nextReduceBlock) {
                    PerMTAWMinted +=
                        ((nextReduceBlock - LastPerMTAWMintedCalcBlock) *
                            currentMTPPB(reduceTimes)) /
                        TotalMTAWs;
                    LastPerMTAWMintedCalcBlock = nextReduceBlock;
                    reduceTimes++;
                    nextReduceBlock += MTProduceReduceInterval;
                } else {
                    PerMTAWMinted +=
                        ((block.number - LastPerMTAWMintedCalcBlock) *
                            currentMTPPB(reduceTimes)) /
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
        return AvatarMTs[avatarId] / 10 ** 52;
    }

    function getAvatarTotalMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return (AvatarMTs[avatarId] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get avatar settled per mopn token allocation weight minted mopn token number
     * @param avatarId avatar Id
     */
    function getAvatarPerMTAWMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return (AvatarMTs[avatarId] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param avatarId avatar Id
     */
    function getAvatarMTAW(uint256 avatarId) public view returns (uint256) {
        return AvatarMTs[avatarId] % 10 ** 12;
    }

    /**
     * @notice mint avatar mopn token
     * @param avatarId avatar Id
     */
    function mintAvatarMT(uint256 avatarId) public {
        uint256 AvatarMTAW = getAvatarMTAW(avatarId);
        uint256 AvatarPerMTAWMinted = getAvatarPerMTAWMinted(avatarId);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        if (AvatarPerMTAWMinted < PerMTAWMinted && AvatarMTAW > 0) {
            uint256 amount = ((((PerMTAWMinted - AvatarPerMTAWMinted) *
                AvatarMTAW) * 90) / 100);
            AvatarMTs[avatarId] +=
                amount *
                10 ** 52 +
                (PerMTAWMinted - AvatarPerMTAWMinted) *
                10 ** 12;
            emit AvatarMTMinted(avatarId, amount);
        }
    }

    function claimAvatarSettledIndexMT(
        uint256 avatarId
    ) public returns (uint256 amount) {
        amount = getAvatarSettledInboxMT(avatarId);
        if (amount > 0) {
            AvatarMTs[avatarId] =
                (AvatarMTs[avatarId] % (10 ** 52)) +
                amount *
                10 ** 32;
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
        return CollectionMTs[COID] / 10 ** 52;
    }

    function getCollectionTotalMinted(
        uint256 COID
    ) public view returns (uint256) {
        return (CollectionMTs[COID] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get collection settled per mopn token allocation weight minted mopn token number
     * @param COID collection Id
     */
    function getCollectionPerMTAWMinted(
        uint256 COID
    ) public view returns (uint256) {
        return (CollectionMTs[COID] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get collection on map mining mopn token allocation weight
     * @param COID collection Id
     */
    function getCollectionMTAW(uint256 COID) public view returns (uint256) {
        return CollectionMTs[COID] % 10 ** 12;
    }

    /**
     * @notice mint collection mopn token
     * @param COID collection Id
     */
    function mintCollectionMT(uint256 COID) public {
        uint256 CollectionMTAW = getCollectionMTAW(COID);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        uint256 CollectionPerMTAWMinted = getCollectionPerMTAWMinted(COID);
        if (CollectionPerMTAWMinted < PerMTAWMinted && CollectionMTAW > 0) {
            uint256 amount = ((((PerMTAWMinted - CollectionPerMTAWMinted) *
                CollectionMTAW) * 5) / 100);
            CollectionMTs[COID] +=
                amount *
                10 ** 52 +
                (PerMTAWMinted - CollectionPerMTAWMinted) *
                10 ** 12;
            emit CollectionMTMinted(COID, amount);
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
    function redeemCollectionInboxMT(
        uint256 avatarId,
        uint256 COID
    ) public onlyAvatar {
        uint256 amount = getCollectionSettledInboxMT(COID);
        if (amount > 0) {
            amount =
                amount /
                (IGovernance(governanceContract).getCollectionOnMapNum(COID) +
                    1);
            CollectionMTs[COID] -= amount * (10 ** 52);
            CollectionMTs[COID] += amount * (10 ** 32);
            AvatarMTs[avatarId] += amount * (10 ** 52);
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
        return LandHolderMTs[LandId] / 10 ** 52;
    }

    function getLandHolderTotalMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return (LandHolderMTs[LandId] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get Land holder settled per mopn token allocation weight minted mopn token number
     * @param LandId MOPN Land Id
     */
    function getLandHolderPerMTAWMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return (LandHolderMTs[LandId] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get Land holder on map mining mopn token allocation weight
     * @param LandId MOPN Land Id
     */
    function getLandHolderMTAW(uint32 LandId) public view returns (uint256) {
        return LandHolderMTs[LandId] % 10 ** 12;
    }

    /**
     * @notice mint Land holder mopn token
     * @param LandId MOPN Land Id
     */
    function mintLandHolderMT(uint32 LandId) public {
        uint256 LandHolderMTAW = getLandHolderMTAW(LandId);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        uint256 LandHolderPerMTAWMinted = getLandHolderPerMTAWMinted(LandId);
        if (LandHolderPerMTAWMinted < PerMTAWMinted && LandHolderMTAW > 0) {
            LandHolderMTs[LandId] +=
                ((((PerMTAWMinted - LandHolderPerMTAWMinted) * LandHolderMTAW) *
                    5) / 100) *
                10 ** 52 +
                (PerMTAWMinted - LandHolderPerMTAWMinted) *
                10 ** 12;
        }
    }

    function claimLandHolderSettledIndexMT(
        uint32 LandId
    ) public returns (uint256 amount) {
        amount = getLandHolderSettledInboxMT(LandId);
        if (amount > 0) {
            LandHolderMTs[LandId] =
                (LandHolderMTs[LandId] % (10 ** 52)) +
                amount *
                10 ** 32;
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

    modifier onlyAvatar() {
        require(
            msg.sender == IGovernance(governanceContract).avatarContract(),
            "not allowed"
        );
        _;
    }
}
