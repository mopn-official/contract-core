// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNMap.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IMOPNMiningData.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MOPNMiningData is IMOPNMiningData, Multicall {
    uint256 public constant MTOutputPerSec = 500000000;

    uint256 public constant MTProduceReduceInterval = 604800;

    uint256 public immutable MTProduceStartTimestamp;

    /// @notice uint32 LastPerNFTPointMintedCalcTimestamp + uint48 TotalWhiteListNFTPoints + uint48 WhiteListFinPerNFTPointMinted  + uint64 PerNFTPointMinted + uint64 TotalNFTPoints
    uint256 public MTProduceData;

    /// @notice uint64 NFTOfferCoefficient + uint64 TotalMTStaking
    uint256 public MTVaultData;

    /// @notice uint64 settled MT + uint64 PerCollectionNFTMinted  + uint64 PerNFTPointMinted + uint64 TotalNFTPoints
    mapping(uint256 => uint256) public AvatarMTs;

    /// @notice uint64 PerCollectionNFTMinted + uint64 PerNFTPointMinted + uint64 CollectionNFTPoints + uint32 WhiteListNFTPoints + uint32 AvatarNFTPoints
    mapping(uint256 => uint256) public CollectionMTs;

    /// @notice uint64 MT Inbox + uint64 totalMTMinted + uint64 OnLandMiningNFT
    mapping(uint32 => uint256) public LandHolderMTs;

    event AvatarMTMinted(uint256 indexed avatarId, uint256 amount);

    event CollectionMTMinted(uint256 indexed COID, uint256 amount);

    event LandHolderMTMinted(uint32 indexed LandId, uint256 amount);

    event MTClaimed(
        uint256 indexed avatarId,
        uint256 indexed COID,
        address indexed to,
        uint256 amount
    );

    event MTClaimedCollectionVault(uint256 indexed COID, uint256 amount);

    event MTClaimedLandHolder(uint256 indexed landId, uint256 amount);

    event NFTOfferAccept(uint256 indexed COID, uint256 tokenId, uint256 price);

    event NFTAuctionAccept(
        uint256 indexed COID,
        uint256 tokenId,
        uint256 price
    );

    event SettleCollectionNFTPoint(uint256 COID);

    IMOPNGovernance public governance;

    constructor(address governance_, uint256 MTProduceStartTimestamp_) {
        MTProduceStartTimestamp = MTProduceStartTimestamp_;
        governance = IMOPNGovernance(governance_);
        MTVaultData = (10 ** 18) << 64;
    }

    function getNFTOfferCoefficient() public view returns (uint256) {
        return uint64(MTProduceData >> 64);
    }

    function getTotalMTStaking() public view returns (uint256) {
        return uint64(MTProduceData);
    }

    function getTotalWhiteListNFTPoints() public view returns (uint256) {
        return uint48(MTProduceData >> 176);
    }

    /**
     * @notice get last per mopn token allocation weight minted settlement timestamp
     */
    function getLastPerNFTPointMintedCalcTimestamp()
        public
        view
        returns (uint256)
    {
        return uint32(MTProduceData >> 224);
    }

    function getWhiteListFinPerNFTPointMinted() public view returns (uint256) {
        return uint48(MTProduceData >> 128);
    }

    /**
     * @notice get settled Per MT Allocation Weight minted mopn token number
     */
    function getPerNFTPointMinted() public view returns (uint256) {
        return uint64(MTProduceData >> 64);
    }

    /**
     * @notice get total mopn token allocation weights
     */
    function getTotalNFTPoints() public view returns (uint256) {
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
        return ABDKMath64x64.mulu(reducePower, MTOutputPerSec);
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
    function settlePerNFTPointMinted() public {
        if (block.timestamp > getLastPerNFTPointMintedCalcTimestamp()) {
            uint256 temp = uint256(uint224(MTProduceData));
            temp += (calcPerNFTPointMinted() - getPerNFTPointMinted()) << 64;

            MTProduceData = (block.timestamp << 224) | temp;
        }
    }

    function closeWhiteList() public onlyGovernance {
        settlePerNFTPointMinted();
        MTProduceData += getPerNFTPointMinted() << 128;
        MTProduceData -= getTotalWhiteListNFTPoints();
    }

    function calcPerNFTPointMinted() public view returns (uint256) {
        if (MTProduceStartTimestamp > block.timestamp) {
            return 0;
        }
        uint256 TotalNFTPoints = getTotalNFTPoints();
        uint256 PerNFTPointMinted = getPerNFTPointMinted();
        if (TotalNFTPoints > 0) {
            uint256 LastPerNFTPointMintedCalcTimestamp = getLastPerNFTPointMintedCalcTimestamp();
            if (MTProduceStartTimestamp > LastPerNFTPointMintedCalcTimestamp) {
                LastPerNFTPointMintedCalcTimestamp = MTProduceStartTimestamp;
            }
            uint256 reduceTimes = (LastPerNFTPointMintedCalcTimestamp -
                MTProduceStartTimestamp) / MTProduceReduceInterval;
            uint256 nextReduceTimestamp = MTProduceStartTimestamp +
                MTProduceReduceInterval +
                reduceTimes *
                MTProduceReduceInterval;

            while (true) {
                if (block.timestamp > nextReduceTimestamp) {
                    PerNFTPointMinted +=
                        ((nextReduceTimestamp -
                            LastPerNFTPointMintedCalcTimestamp) *
                            currentMTPPS(reduceTimes)) /
                        TotalNFTPoints;
                    LastPerNFTPointMintedCalcTimestamp = nextReduceTimestamp;
                    reduceTimes++;
                    nextReduceTimestamp += MTProduceReduceInterval;
                } else {
                    PerNFTPointMinted +=
                        ((block.timestamp -
                            LastPerNFTPointMintedCalcTimestamp) *
                            currentMTPPS(reduceTimes)) /
                        TotalNFTPoints;
                    break;
                }
            }
        }
        return PerNFTPointMinted;
    }

    /**
     * @notice get avatar settled unclaimed minted mopn token
     * @param avatarId avatar Id
     */
    function getAvatarSettledMT(
        uint256 avatarId
    ) public view returns (uint256) {
        return uint64(AvatarMTs[avatarId] >> 192);
    }

    function getAvatarCollectionPerNFTMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return uint64(AvatarMTs[avatarId] >> 128);
    }

    /**
     * @notice get avatar settled per mopn token allocation weight minted mopn token number
     * @param avatarId avatar Id
     */
    function getAvatarPerNFTPointMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return uint64(AvatarMTs[avatarId] >> 64);
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param avatarId avatar Id
     */
    function getAvatarNFTPoint(
        uint256 avatarId
    ) public view returns (uint256 point) {
        return uint64(AvatarMTs[avatarId]);
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param avatarId avatar Id
     */
    function calcAvatarMT(
        uint256 avatarId
    ) public view returns (uint256 inbox) {
        inbox = getAvatarSettledMT(avatarId);
        uint256 AvatarNFTPoint = getAvatarNFTPoint(avatarId);
        uint256 AvatarPerNFTPointMintedDiff = calcPerNFTPointMinted() -
            getAvatarPerNFTPointMinted(avatarId);

        if (AvatarPerNFTPointMintedDiff > 0 && AvatarNFTPoint > 0) {
            uint256 AvatarCollectionPerNFTMintedDiff = getPerCollectionNFTMinted(
                    IMOPN(governance.mopnContract()).getAvatarCOID(avatarId)
                ) - getAvatarCollectionPerNFTMinted(avatarId);
            inbox +=
                ((AvatarPerNFTPointMintedDiff * AvatarNFTPoint) * 90) /
                100;
            if (AvatarCollectionPerNFTMintedDiff > 0) {
                inbox += (AvatarCollectionPerNFTMintedDiff * 90) / 100;
            }
        }
    }

    /**
     * @notice mint avatar mopn token
     * @param avatarId avatar Id
     */
    function mintAvatarMT(uint256 avatarId) public returns (uint256) {
        uint256 AvatarNFTPoint = getAvatarNFTPoint(avatarId);
        uint256 AvatarPerNFTPointMintedDiff = getPerNFTPointMinted() -
            getAvatarPerNFTPointMinted(avatarId);

        if (AvatarPerNFTPointMintedDiff > 0) {
            uint256 collectionPerNFTMintedDiff = getPerCollectionNFTMinted(
                IMOPN(governance.mopnContract()).getAvatarCOID(avatarId)
            ) - getAvatarCollectionPerNFTMinted(avatarId);
            if (AvatarNFTPoint > 0) {
                uint256 amount = ((AvatarPerNFTPointMintedDiff) *
                    AvatarNFTPoint);
                if (collectionPerNFTMintedDiff > 0) {
                    amount += collectionPerNFTMintedDiff;
                }

                uint32 LandId = IMOPNMap(governance.mapContract())
                    .getTileLandId(
                        IMOPN(governance.mopnContract()).getAvatarCoordinate(
                            avatarId
                        )
                    );
                uint256 landamount = (amount * 5) / 100;
                LandHolderMTs[LandId] += (landamount << 128) | landamount;
                emit LandHolderMTMinted(LandId, landamount);

                amount = (amount * 90) / 100;

                AvatarMTs[avatarId] +=
                    (amount << 192) |
                    (collectionPerNFTMintedDiff << 128) |
                    (AvatarPerNFTPointMintedDiff << 64);
                emit AvatarMTMinted(avatarId, amount);
            } else {
                AvatarMTs[avatarId] +=
                    (collectionPerNFTMintedDiff << 128) |
                    (AvatarPerNFTPointMintedDiff << 64);
            }
        }
        return AvatarNFTPoint;
    }

    /**
     * @notice redeem avatar unclaimed minted mopn token
     * @param avatarId avatar Id
     */
    function redeemAvatarMT(uint256 avatarId) public {
        address nftOwner = IMOPN(governance.mopnContract()).ownerOf(avatarId);

        settlePerNFTPointMinted();

        uint256 COID = IMOPN(governance.mopnContract()).getAvatarCOID(avatarId);
        mintCollectionMT(COID);
        mintAvatarMT(avatarId);

        uint256 amount = getAvatarSettledMT(avatarId);
        if (amount > 0) {
            AvatarMTs[avatarId] -= amount << 192;
            governance.mintMT(nftOwner, amount);
            emit MTClaimed(avatarId, COID, nftOwner, amount);
        }
    }

    function getPerCollectionNFTMinted(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(CollectionMTs[COID] >> 192);
    }

    /**
     * @notice get collection settled per mopn token allocation weight minted mopn token number
     * @param COID collection Id
     */
    function getCollectionPerNFTPointMinted(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(CollectionMTs[COID] >> 128);
    }

    /**
     * @notice get collection on map mining mopn token allocation weight
     * @param COID collection Id
     */
    function getCollectionNFTPoint(uint256 COID) public view returns (uint256) {
        return uint64(CollectionMTs[COID] >> 64);
    }

    function getCollectionWhiteListNFTPoint(
        uint256 COID
    ) public view returns (uint256) {
        return uint32(CollectionMTs[COID] >> 32);
    }

    /**
     * @notice get collection avatars on map mining mopn token allocation weight
     * @param COID collection Id
     */
    function getCollectionAvatarNFTPoint(
        uint256 COID
    ) public view returns (uint256) {
        return uint32(CollectionMTs[COID]);
    }

    function getCollectionPoint(
        uint256 COID
    ) public view returns (uint256 point) {
        if (governance.getCollectionVault(COID) != address(0)) {
            point =
                IMOPNToken(governance.mtContract()).balanceOf(
                    governance.getCollectionVault(COID)
                ) /
                10 ** 8;
        }
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param COID collection Id
     */
    function calcCollectionMT(
        uint256 COID
    ) public view returns (uint256 inbox) {
        inbox = IMOPN(governance.mopnContract()).getCollectionMintedMT(COID);
        uint256 PerNFTPointMinted = calcPerNFTPointMinted();
        uint256 CollectionPerNFTPointMinted = getCollectionPerNFTPointMinted(
            COID
        );
        uint256 WhiteListNFTPoints = getCollectionWhiteListNFTPoint(COID);
        uint256 CollectionNFTPoint = getCollectionNFTPoint(COID);
        uint256 AvatarNFTPoint = getCollectionAvatarNFTPoint(COID);

        if (
            CollectionPerNFTPointMinted < PerNFTPointMinted &&
            AvatarNFTPoint > 0
        ) {
            inbox +=
                (((PerNFTPointMinted - CollectionPerNFTPointMinted) *
                    (CollectionNFTPoint + AvatarNFTPoint)) * 5) /
                100;
            if (WhiteListNFTPoints > 0) {
                if (getWhiteListFinPerNFTPointMinted() > 0) {
                    inbox +=
                        (((getWhiteListFinPerNFTPointMinted() -
                            CollectionPerNFTPointMinted) * WhiteListNFTPoints) *
                            5) /
                        100;
                } else {
                    inbox +=
                        (((PerNFTPointMinted - CollectionPerNFTPointMinted) *
                            WhiteListNFTPoints) * 5) /
                        100;
                }
            }
        }
    }

    /**
     * @notice mint collection mopn token
     * @param COID collection Id
     */
    function mintCollectionMT(uint256 COID) public {
        uint256 collectionPerNFTPointMinted = getCollectionPerNFTPointMinted(
            COID
        );
        uint256 CollectionPerNFTPointMintedDiff = getPerNFTPointMinted() -
            collectionPerNFTPointMinted;
        if (CollectionPerNFTPointMintedDiff > 0) {
            uint256 AvatarNFTPoint = getCollectionAvatarNFTPoint(COID);
            if (AvatarNFTPoint > 0) {
                uint256 CollectionMT = CollectionMTs[COID];
                uint256 CollectionNFTPoint = getCollectionNFTPoint(COID);
                uint256 amount = ((CollectionPerNFTPointMintedDiff *
                    AvatarNFTPoint) * 5) / 100;
                CollectionMT += (CollectionPerNFTPointMintedDiff << 128);

                if (CollectionNFTPoint > 0) {
                    amount = (((CollectionPerNFTPointMintedDiff *
                        CollectionNFTPoint) * 5) / 100);
                    CollectionMT += (((CollectionPerNFTPointMintedDiff *
                        CollectionNFTPoint) /
                        IMOPN(governance.mopnContract()).getCollectionOnMapNum(
                            COID
                        )) << 192);
                }

                uint256 WhiteListNFTPoint = getCollectionWhiteListNFTPoint(
                    COID
                );
                if (WhiteListNFTPoint > 0) {
                    uint256 whiteListFinPerNFTPointMinted = getWhiteListFinPerNFTPointMinted();
                    if (whiteListFinPerNFTPointMinted > 0) {
                        if (
                            whiteListFinPerNFTPointMinted >
                            collectionPerNFTPointMinted
                        ) {
                            amount = ((((whiteListFinPerNFTPointMinted -
                                collectionPerNFTPointMinted) *
                                WhiteListNFTPoint) * 5) / 100);
                            CollectionMT +=
                                (((whiteListFinPerNFTPointMinted -
                                    collectionPerNFTPointMinted) *
                                    WhiteListNFTPoint) /
                                    IMOPN(governance.mopnContract())
                                        .getCollectionOnMapNum(COID)) <<
                                192;
                            CollectionMT -= WhiteListNFTPoint << 32;
                        }
                    } else {
                        amount = (((CollectionPerNFTPointMintedDiff *
                            WhiteListNFTPoint) * 5) / 100);
                        CollectionMT +=
                            (((CollectionPerNFTPointMintedDiff) *
                                WhiteListNFTPoint) /
                                IMOPN(governance.mopnContract())
                                    .getCollectionOnMapNum(COID)) <<
                            192;
                    }
                }

                CollectionMTs[COID] = CollectionMT;
                IMOPN(governance.mopnContract()).addCollectionMintedMT(
                    COID,
                    amount
                );
                emit CollectionMTMinted(COID, amount);
            } else {
                CollectionMTs[COID] += CollectionPerNFTPointMintedDiff << 128;
            }
        }
    }

    function redeemCollectionMT(uint256 COID) public {
        uint256 amount = IMOPN(governance.mopnContract()).getCollectionMintedMT(
            COID
        );
        if (amount > 0) {
            governance.mintMT(governance.getCollectionVault(COID), amount);
            IMOPN(governance.mopnContract()).clearCollectionMintedMT(COID);
            MTVaultData += amount;
            emit MTClaimedCollectionVault(COID, amount);
        }
    }

    function settleCollectionNFTPoint(
        uint256 COID
    ) public onlyAvatarOrCollectionVault(COID) {
        _settleCollectionNFTPoint(COID);

        emit SettleCollectionNFTPoint(COID);
    }

    function _settleCollectionNFTPoint(uint256 COID) internal {
        uint256 point = getCollectionPoint(COID);
        uint256 collectionNFTPoint;
        if (point > 0) {
            collectionNFTPoint =
                point *
                IMOPN(governance.mopnContract()).getCollectionOnMapNum(COID);
        }
        uint256 preCollectionNFTPoint = getCollectionNFTPoint(COID);
        if (collectionNFTPoint != preCollectionNFTPoint) {
            if (collectionNFTPoint > preCollectionNFTPoint) {
                MTProduceData += collectionNFTPoint - preCollectionNFTPoint;
                CollectionMTs[COID] += ((collectionNFTPoint -
                    preCollectionNFTPoint) << 64);
            } else {
                MTProduceData -= preCollectionNFTPoint;
                MTProduceData += collectionNFTPoint;
                CollectionMTs[COID] -= ((preCollectionNFTPoint -
                    collectionNFTPoint) << 64);
            }
        }

        uint256 additionalpoint = IMOPN(governance.mopnContract())
            .getCollectionAdditionalNFTPoints(COID);
        uint256 collectionAdditionalNFTPoint;
        if (additionalpoint > 0) {
            collectionAdditionalNFTPoint =
                additionalpoint *
                IMOPN(governance.mopnContract()).getCollectionOnMapNum(COID);
        }
        uint256 preCollectionAdditionalNFTPoint = getCollectionWhiteListNFTPoint(
                COID
            );
        if (collectionAdditionalNFTPoint != preCollectionAdditionalNFTPoint) {
            if (
                collectionAdditionalNFTPoint > preCollectionAdditionalNFTPoint
            ) {
                MTProduceData +=
                    collectionAdditionalNFTPoint -
                    preCollectionAdditionalNFTPoint;
                CollectionMTs[COID] += ((collectionAdditionalNFTPoint -
                    preCollectionAdditionalNFTPoint) << 32);
            } else {
                MTProduceData -= preCollectionAdditionalNFTPoint;
                MTProduceData += collectionAdditionalNFTPoint;
                CollectionMTs[COID] -= ((preCollectionAdditionalNFTPoint -
                    collectionAdditionalNFTPoint) << 32);
            }
        }
    }

    function settleCollectionMining(
        uint256 COID
    ) public onlyAvatarOrCollectionVault(COID) {
        settlePerNFTPointMinted();
        mintCollectionMT(COID);
        redeemCollectionMT(COID);
    }

    /**
     * @notice get Land holder settled minted unclaimed mopn token
     * @param LandId MOPN Land Id
     */
    function getLandHolderInboxMT(uint32 LandId) public view returns (uint256) {
        return uint128(LandHolderMTs[LandId] >> 128);
    }

    function getLandHolderTotalMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return uint128(LandHolderMTs[LandId]);
    }

    function redeemLandHolderMT(uint32 LandId) public {
        uint256 amount = getLandHolderInboxMT(LandId);
        if (amount > 0) {
            address owner = IMOPNLand(governance.landContract()).ownerOf(
                LandId
            );
            governance.mintMT(owner, amount);
            LandHolderMTs[LandId] = uint128(LandHolderMTs[LandId]);
            emit MTClaimedLandHolder(LandId, amount);
        }
    }

    function batchRedeemSameLandHolderMT(uint32[] memory LandIds) public {
        uint256 amount;
        address owner;
        for (uint256 i = 0; i < LandIds.length; i++) {
            if (owner == address(0)) {
                owner = IMOPNLand(governance.landContract()).ownerOf(
                    LandIds[i]
                );
            } else {
                require(
                    owner ==
                        IMOPNLand(governance.landContract()).ownerOf(
                            LandIds[i]
                        ),
                    "not same owner"
                );
            }
            amount += getLandHolderInboxMT(LandIds[i]);
            LandHolderMTs[LandIds[i]] = uint128(LandHolderMTs[LandIds[i]]);
        }
        if (amount > 0) {
            governance.mintMT(owner, amount);
        }
    }

    function addNFTPoint(
        uint256 avatarId,
        uint256 COID,
        uint256 amount
    ) public onlyAvatarOrMap {
        _addNFTPoint(avatarId, COID, amount);
    }

    function subNFTPoint(
        uint256 avatarId,
        uint256 COID
    ) public onlyAvatarOrMap {
        _subNFTPoint(avatarId, COID);
    }

    /**
     * add on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param amount EAW amount
     */
    function _addNFTPoint(
        uint256 avatarId,
        uint256 COID,
        uint256 amount
    ) internal {
        amount *= 100;
        settlePerNFTPointMinted();
        mintCollectionMT(COID);
        uint256 exist = mintAvatarMT(avatarId);
        _settleCollectionNFTPoint(COID);

        if (exist == 0 && getWhiteListFinPerNFTPointMinted() == 0) {
            uint256 collectionAdditionalNFTPoints = IMOPN(
                governance.mopnContract()
            ).getCollectionAdditionalNFTPoints(COID);
            if (collectionAdditionalNFTPoints > 0) {
                MTProduceData +=
                    (collectionAdditionalNFTPoints << 176) |
                    (amount + collectionAdditionalNFTPoints);
                CollectionMTs[COID] +=
                    (collectionAdditionalNFTPoints << 32) |
                    amount;
            } else {
                MTProduceData += amount;
                CollectionMTs[COID] += amount;
            }
        } else {
            MTProduceData += amount;
            CollectionMTs[COID] += amount;
        }

        AvatarMTs[avatarId] += amount;
    }

    /**
     * substruct on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     */
    function _subNFTPoint(uint256 avatarId, uint256 COID) internal {
        settlePerNFTPointMinted();
        mintCollectionMT(COID);
        uint256 amount = mintAvatarMT(avatarId);
        _settleCollectionNFTPoint(COID);

        if (getWhiteListFinPerNFTPointMinted() == 0) {
            uint256 collectionAdditionalNFTPoints = IMOPN(
                governance.mopnContract()
            ).getCollectionAdditionalNFTPoints(COID);
            if (collectionAdditionalNFTPoints > 0) {
                MTProduceData -=
                    (collectionAdditionalNFTPoints << 176) |
                    (amount + collectionAdditionalNFTPoints);
                CollectionMTs[COID] -=
                    (collectionAdditionalNFTPoints << 32) |
                    amount;
            } else {
                MTProduceData -= amount;
                CollectionMTs[COID] -= amount;
            }
        } else {
            MTProduceData -= amount;
            CollectionMTs[COID] -= amount;
        }

        AvatarMTs[avatarId] -= amount;
    }

    function NFTOfferAcceptNotify(
        uint256 COID,
        uint256 price,
        uint256 tokenId
    ) public {
        uint256 totalMTStaking = getTotalMTStaking();
        MTVaultData =
            ((((totalMTStaking + 10000 - price) * getNFTOfferCoefficient()) /
                totalMTStaking +
                10000) << 64) |
            totalMTStaking;
        emit NFTOfferAccept(COID, tokenId, price);
    }

    function NFTAuctionAcceptNotify(
        uint256 COID,
        uint256 price,
        uint256 tokenId
    ) public {
        emit NFTAuctionAccept(COID, tokenId, price);
    }

    function changeTotalMTStaking(
        uint256 COID,
        bool increase,
        uint256 amount
    ) public onlyAvatarOrCollectionVault(COID) {
        if (increase) {
            MTVaultData += amount;
        } else {
            MTVaultData -= amount;
        }
    }

    modifier onlyAvatarOrCollectionVault(uint256 COID) {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.getCollectionVault(COID),
            "only collection vault allowed"
        );
        _;
    }

    modifier onlyAvatarOrMap() {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.mapContract(),
            "only avatar and map allowed"
        );
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "only governance allowed");
        _;
    }
}
