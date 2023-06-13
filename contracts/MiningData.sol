// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/IMap.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/ILand.sol";
import "./interfaces/IMiningData.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MiningData is IMiningData, Multicall {
    uint256 public constant MTProducePerSecond = 50000000000;

    uint256 public constant MTProduceReduceInterval = 604800;

    uint256 public immutable MTProduceStartTimestamp;

    /// @notice uint64 PerNFTPointMinted + uint64 LastPerNFTPointMintedCalcTimestamp + uint64 TotalNFTPoints
    uint256 public MTProduceData;

    /// @notice uint64 MT Inbox + uint64 CollectionPerNFTMinted + uint64 PerNFTPointMinted + uint64 TotalNFTPoints
    mapping(uint256 => uint256) public AvatarMTs;

    /// @notice uint64 CollectionPerNFTMinted + uint64 PerNFTPointMinted + uint64 CollectionNFTPoints + uint64 AvatarNFTPoints
    mapping(uint256 => uint256) public CollectionMTs;

    /// @notice uint64 MT Inbox + uint64 totalMTMinted + uint64 OnLandMiningNFT
    mapping(uint32 => uint256) public LandHolderMTs;

    uint256 public NFTOfferCoefficient;

    uint256 public totalMTStaking;

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

    IGovernance public governance;

    constructor(address governance_, uint256 MTProduceStartTimestamp_) {
        MTProduceStartTimestamp = MTProduceStartTimestamp_;
        governance = IGovernance(governance_);
        NFTOfferCoefficient = 10 ** 18;
    }

    function getNFTOfferCoefficient() public view returns (uint256) {
        return NFTOfferCoefficient;
    }

    /**
     * @notice get settled Per MT Allocation Weight minted mopn token number
     */
    function getPerNFTPointMinted() public view returns (uint256) {
        return uint64(MTProduceData >> 128);
    }

    /**
     * @notice get last per mopn token allocation weight minted settlement timestamp
     */
    function getLastPerNFTPointMintedCalcTimestamp()
        public
        view
        returns (uint256)
    {
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
    function settlePerNFTPointMinted() public {
        if (block.timestamp > getLastPerNFTPointMintedCalcTimestamp()) {
            uint256 PerNFTPointMinted = calcPerNFTPointMinted();
            MTProduceData =
                (PerNFTPointMinted << 128) |
                (block.timestamp << 64) |
                getTotalNFTPoints();
        }
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
    function getAvatarNFTPoint(uint256 avatarId) public view returns (uint256) {
        uint256 COID = IAvatar(governance.avatarContract()).getAvatarCOID(
            avatarId
        );
        return uint64(AvatarMTs[avatarId]) + getCollectionPoint(COID);
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
        uint256 AvatarCollectionPerNFTMintedDiff = getCollectionPerNFTMinted(
            IAvatar(governance.avatarContract()).getAvatarCOID(avatarId)
        ) - getAvatarCollectionPerNFTMinted(avatarId);

        if (AvatarPerNFTPointMintedDiff > 0 && AvatarNFTPoint > 0) {
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
            uint256 AvatarCollectionPerNFTMintedDiff = getCollectionPerNFTMinted(
                    IAvatar(governance.avatarContract()).getAvatarCOID(avatarId)
                ) - getAvatarCollectionPerNFTMinted(avatarId);
            if (AvatarNFTPoint > 0) {
                uint256 amount = ((AvatarPerNFTPointMintedDiff) *
                    AvatarNFTPoint);
                if (AvatarCollectionPerNFTMintedDiff > 0) {
                    amount += AvatarCollectionPerNFTMintedDiff;
                }

                uint32 LandId = IMap(governance.mapContract()).getTileLandId(
                    IAvatar(governance.avatarContract()).getAvatarCoordinate(
                        avatarId
                    )
                );
                LandHolderMTs[LandId] += ((amount * 5) / 100) << 128;

                amount = (amount * 90) / 100;

                AvatarMTs[avatarId] +=
                    (amount << 192) |
                    (AvatarCollectionPerNFTMintedDiff << 128) |
                    (AvatarPerNFTPointMintedDiff << 64);
                emit AvatarMTMinted(avatarId, amount);
            } else {
                AvatarMTs[avatarId] +=
                    (AvatarCollectionPerNFTMintedDiff << 128) |
                    (AvatarPerNFTPointMintedDiff << 64);
            }
        }
        return AvatarNFTPoint;
    }

    /**
     * @notice redeem avatar unclaimed minted mopn token
     * @param avatarId avatar Id
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    function redeemAvatarMT(
        uint256 avatarId,
        IAvatar.DelegateWallet delegateWallet,
        address vault
    ) public {
        address nftOwner = IAvatar(governance.avatarContract()).ownerOf(
            avatarId,
            delegateWallet,
            vault
        );

        settlePerNFTPointMinted();

        uint256 COID = IAvatar(governance.avatarContract()).getAvatarCOID(
            avatarId
        );
        mintCollectionMT(COID);
        mintAvatarMT(avatarId);

        uint256 amount = getAvatarSettledMT(avatarId);
        if (amount > 0) {
            AvatarMTs[avatarId] -= amount << 192;
            governance.mintMT(nftOwner, amount);
            emit MTClaimed(avatarId, COID, nftOwner, amount);
        }
    }

    function getCollectionPerNFTMinted(
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

    /**
     * @notice get collection avatars on map mining mopn token allocation weight
     * @param COID collection Id
     */
    function getCollectionAvatarNFTPoint(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(CollectionMTs[COID]);
    }

    function getCollectionPoint(
        uint256 COID
    ) public view returns (uint256 point) {
        if (governance.getCollectionVault(COID) != address(0)) {
            point =
                IMOPNToken(governance.mtContract()).balanceOf(
                    governance.getCollectionVault(COID)
                ) /
                10 ** 7;
        }
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param COID collection Id
     */
    function calcCollectionMT(
        uint256 COID
    ) public view returns (uint256 inbox) {
        inbox = governance.getCollectionMintedMT(COID);
        uint256 PerNFTPointMinted = calcPerNFTPointMinted();
        uint256 CollectionPerNFTPointMinted = getCollectionPerNFTPointMinted(
            COID
        );
        uint256 CollectionNFTPoint = getCollectionNFTPoint(COID);
        uint256 AvatarNFTPoint = getCollectionAvatarNFTPoint(COID);

        if (
            CollectionPerNFTPointMinted < PerNFTPointMinted &&
            (CollectionNFTPoint > 0 || AvatarNFTPoint > 0)
        ) {
            inbox +=
                (((PerNFTPointMinted - CollectionPerNFTPointMinted) *
                    (CollectionNFTPoint + AvatarNFTPoint)) * 5) /
                100;
        }
    }

    /**
     * @notice mint collection mopn token
     * @param COID collection Id
     */
    function mintCollectionMT(uint256 COID) public {
        uint256 CollectionNFTPoint = getCollectionNFTPoint(COID);
        uint256 AvatarNFTPoint = getCollectionAvatarNFTPoint(COID);
        uint256 CollectionPerNFTPointMintedDiff = getPerNFTPointMinted() -
            getCollectionPerNFTPointMinted(COID);
        if (CollectionPerNFTPointMintedDiff > 0) {
            if (CollectionNFTPoint > 0 || AvatarNFTPoint > 0) {
                uint256 amount = (((CollectionPerNFTPointMintedDiff *
                    (CollectionNFTPoint + AvatarNFTPoint)) * 5) / 100);
                governance.addCollectionMintedMT(COID, amount);

                if (CollectionNFTPoint > 0) {
                    CollectionMTs[COID] +=
                        (((CollectionPerNFTPointMintedDiff *
                            CollectionNFTPoint) /
                            governance.getCollectionOnMapNum(COID)) << 192) |
                        (CollectionPerNFTPointMintedDiff << 128);
                } else {
                    CollectionMTs[COID] += (CollectionPerNFTPointMintedDiff <<
                        128);
                }

                emit CollectionMTMinted(COID, amount);
            } else {
                CollectionMTs[COID] += CollectionPerNFTPointMintedDiff << 128;
            }
        }
    }

    function redeemCollectionMT(uint256 COID) public {
        uint256 amount = governance.getCollectionMintedMT(COID);
        governance.mintMT(governance.getCollectionVault(COID), amount);
        governance.clearCollectionMintedMT(COID);
        totalMTStaking += amount;
    }

    function settleCollectionNFTPoint(
        uint256 COID
    ) public onlyCollectionVault(COID) {
        uint256 point = getCollectionPoint(COID);
        uint256 collectionNFTPoint;
        if (point > 0) {
            collectionNFTPoint = point * governance.getCollectionOnMapNum(COID);
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
    }

    function settleCollectionMining(
        uint256 COID
    ) public onlyCollectionVault(COID) {
        settlePerNFTPointMinted();
        mintCollectionMT(COID);
        redeemCollectionMT(COID);
    }

    /**
     * @notice get Land holder settled minted unclaimed mopn token
     * @param LandId MOPN Land Id
     */
    function getLandHolderInboxMT(uint32 LandId) public view returns (uint256) {
        return uint64(LandHolderMTs[LandId] >> 128);
    }

    function getLandHolderTotalMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return uint64(LandHolderMTs[LandId] >> 64);
    }

    /**
     * @notice get Land holder settled per mopn token allocation weight minted mopn token number
     * @param LandId MOPN Land Id
     */
    function getOnLandMiningNFT(uint32 LandId) public view returns (uint256) {
        return uint64(LandHolderMTs[LandId]);
    }

    function redeemLandHolderMT(uint32 LandId) public {
        uint256 amount = getLandHolderInboxMT(LandId);
        if (amount > 0) {
            address owner = ILand(governance.landContract()).ownerOf(LandId);
            governance.mintMT(owner, amount);
            LandHolderMTs[LandId] = uint128(LandHolderMTs[LandId]);
        }
    }

    function batchRedeemSameLandHolderMT(uint32[] memory LandIds) public {
        uint256 amount;
        address owner;
        for (uint256 i = 0; i < LandIds.length; i++) {
            if (owner == address(0)) {
                owner = ILand(governance.landContract()).ownerOf(LandIds[i]);
            } else {
                require(
                    owner ==
                        ILand(governance.landContract()).ownerOf(LandIds[i]),
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
        amount *= 10 ** 8;
        settlePerNFTPointMinted();
        mintCollectionMT(COID);
        uint256 onMapNFTPoint = mintAvatarMT(avatarId);
        if (onMapNFTPoint == 0) {
            governance.addCollectionOnMapNum(COID);
        }
        settleCollectionNFTPoint(COID);

        MTProduceData += amount;
        CollectionMTs[COID] += amount;
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
        governance.subCollectionOnMapNum(COID);
        settleCollectionNFTPoint(COID);

        MTProduceData -= amount;
        CollectionMTs[COID] -= amount;
        AvatarMTs[avatarId] -= amount;
    }

    function NFTOfferAcceptNotify(uint256 price) public {
        NFTOfferCoefficient =
            ((totalMTStaking - price) * NFTOfferCoefficient) /
            totalMTStaking;
    }

    function changeTotalMTStaking(
        uint256 COID,
        bool increase,
        uint256 amount
    ) public onlyCollectionVault(COID) {
        if (increase) {
            totalMTStaking += amount;
        } else {
            totalMTStaking -= amount;
        }
    }

    modifier onlyCollectionVault(uint256 COID) {
        require(
            msg.sender == governance.getCollectionVault(COID),
            "not allowed"
        );
        _;
    }

    modifier onlyAvatarOrMap() {
        require(
            msg.sender == governance.avatarContract() ||
                msg.sender == governance.mapContract(),
            "not allowed"
        );
        _;
    }
}
