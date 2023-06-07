// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/IMap.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMOPNToken.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MiningData is Multicall {
    uint256 public constant MTProducePerSecond = 50000000000;

    uint256 public constant MTProduceReduceInterval = 604800;

    uint256 public immutable MTProduceStartTimestamp;

    /// @notice uint64 PerMTAWMinted + uint64 LastPerMTAWMintedCalcTimestamp + uint64 TotalMTAWs
    uint256 public MTProduceData;

    /// @notice uint64 MT Inbox + uint64 CollectionPerNFTMinted + uint64 PerMTAWMinted + uint64 TotalMTAWs
    mapping(uint256 => uint256) public AvatarMTs;

    /// @notice uint64 CollectionPerNFTMinted + uint64 PerMTAWMinted + uint64 CollectionMTAWs + uint64 AvatarMTAWs
    mapping(uint256 => uint256) public CollectionMTs;

    /// @notice uint64 MT Inbox + uint64 totalMTMinted + uint64 OnLandMiningNFT
    mapping(uint32 => uint256) public LandHolderMTs;

    uint256 public NFTOfferCoefficient;

    uint256 public totalMTPledge;

    event AvatarMTMinted(uint256 indexed avatarId, uint256 amount);

    event CollectionMTMinted(uint256 indexed COID, uint256 amount);

    event LandHolderMTMinted(uint32 indexed LandId, uint256 amount);

    event MTClaimed(
        uint256 indexed avatarId,
        uint256 indexed COID,
        address indexed to,
        uint256 amount
    );

    event MTClaimedCollectionVault(
        uint256 indexed avatarId,
        uint256 indexed COID,
        address indexed to,
        uint256 amount
    );

    IGovernance public governance;

    constructor(uint256 MTProduceStartTimestamp_, address governance_) {
        MTProduceStartTimestamp = MTProduceStartTimestamp_;
        governance = IGovernance(governance_);
        NFTOfferCoefficient = 10 ** 18;
    }

    /**
     * @notice redeem avatar unclaimed minted mopn token
     * @param avatarId avatar Id
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    function redeemAvatarInboxMT(
        uint256 avatarId,
        IAvatar.DelegateWallet delegateWallet,
        address vault
    ) public {
        address nftOwner = IAvatar(governance.avatarContract()).ownerOf(
            avatarId,
            delegateWallet,
            vault
        );
        uint32 avatarTile = IAvatar(governance.avatarContract())
            .getAvatarCoordinate(avatarId);
        uint256 COID = IAvatar(governance.avatarContract()).getAvatarCOID(
            avatarId
        );
        if (avatarTile > 0) {
            settlePerMTAWMinted();
            mintCollectionMT(COID);
            mintAvatarMT(
                avatarId,
                IMap(governance.mapContract()).getTileLandId(avatarTile)
            );
        }

        uint256 amount = claimAvatarSettledIndexMT(avatarId);
        if (amount > 0) {
            governance.mintMT(nftOwner, amount);
            emit MTClaimed(avatarId, COID, nftOwner, amount);
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
            if (MTProduceStartTimestamp > LastPerMTAWMintedCalcTimestamp) {
                LastPerMTAWMintedCalcTimestamp = MTProduceStartTimestamp;
            }
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

    function getAvatarCollectionPerNFTMinted(
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
    function mintAvatarMT(
        uint256 avatarId,
        uint32 LandId
    ) public returns (uint256) {
        uint256 AvatarMTAW = getAvatarMTAW(avatarId);
        uint256 AvatarPerMTAWMintedDiff = getPerMTAWMinted() -
            getAvatarPerMTAWMinted(avatarId);
        uint256 AvatarCollectionPerNFTMintedDiff = getCollectionPerNFTMinted(
            IAvatar(governance.avatarContract()).getAvatarCOID(avatarId)
        ) - getAvatarCollectionPerNFTMinted(avatarId);
        if (AvatarPerMTAWMintedDiff > 0) {
            if (AvatarMTAW > 0) {
                uint256 amount = ((AvatarPerMTAWMintedDiff) * AvatarMTAW);
                if (AvatarCollectionPerNFTMintedDiff > 0) {
                    amount += AvatarCollectionPerNFTMintedDiff;
                }

                LandHolderMTs[LandId] += ((amount * 5) / 100) << 128;

                amount = (amount * 90) / 100;

                AvatarMTs[avatarId] +=
                    (amount << 192) |
                    (AvatarCollectionPerNFTMintedDiff << 128) |
                    (AvatarPerMTAWMintedDiff << 64);
                emit AvatarMTMinted(avatarId, amount);
            } else {
                AvatarMTs[avatarId] +=
                    (AvatarCollectionPerNFTMintedDiff << 128) |
                    (AvatarPerMTAWMintedDiff << 64);
            }
        }
        return AvatarMTAW;
    }

    function claimAvatarSettledIndexMT(
        uint256 avatarId
    ) internal returns (uint256 amount) {
        amount = getAvatarSettledInboxMT(avatarId);
        if (amount > 0) {
            AvatarMTs[avatarId] -= amount << 192;
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
        uint256 AvatarMTAW = getAvatarMTAW(avatarId);
        uint256 AvatarPerMTAWMintedDiff = calcPerMTAWMinted() -
            getAvatarPerMTAWMinted(avatarId);
        uint256 AvatarCollectionPerNFTMintedDiff = getCollectionPerNFTMinted(
            IAvatar(governance.avatarContract()).getAvatarCOID(avatarId)
        ) - getAvatarCollectionPerNFTMinted(avatarId);

        if (AvatarPerMTAWMintedDiff > 0 && AvatarMTAW > 0) {
            inbox += ((AvatarPerMTAWMintedDiff * AvatarMTAW) * 90) / 100;
            if (AvatarCollectionPerNFTMintedDiff > 0) {
                inbox += (AvatarCollectionPerNFTMintedDiff * 90) / 100;
            }
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
    function getCollectionPerMTAWMinted(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(CollectionMTs[COID] >> 128);
    }

    /**
     * @notice get collection on map mining mopn token allocation weight
     * @param COID collection Id
     */
    function getCollectionMTAW(uint256 COID) public view returns (uint256) {
        return uint64(CollectionMTs[COID] >> 64);
    }

    /**
     * @notice get collection avatars on map mining mopn token allocation weight
     * @param COID collection Id
     */
    function getCollectionAvatarMTAW(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(CollectionMTs[COID]);
    }

    /**
     * @notice mint collection mopn token
     * @param COID collection Id
     */
    function mintCollectionMT(uint256 COID) public {
        uint256 CollectionMTAW = getCollectionMTAW(COID);
        uint256 AvatarMTAW = getCollectionAvatarMTAW(COID);
        uint256 CollectionPerMTAWMintedDiff = getPerMTAWMinted() -
            getCollectionPerMTAWMinted(COID);
        if (CollectionPerMTAWMintedDiff > 0) {
            if (CollectionMTAW > 0 || AvatarMTAW > 0) {
                uint256 amount = (((CollectionPerMTAWMintedDiff *
                    (CollectionMTAW + AvatarMTAW)) * 5) / 100);
                if (governance.getCollectionVault(COID) != address(0)) {
                    governance.mintMT(
                        governance.getCollectionVault(COID),
                        amount
                    );
                    totalMTPledge += amount;
                } else {
                    governance.addCollectionMintedMT(COID, amount);
                }

                if (CollectionMTAW > 0) {
                    CollectionMTs[COID] +=
                        (((CollectionPerMTAWMintedDiff * CollectionMTAW) /
                            governance.getCollectionOnMapNum(COID)) << 192) |
                        (CollectionPerMTAWMintedDiff << 128);
                } else {
                    CollectionMTs[COID] += (CollectionPerMTAWMintedDiff << 128);
                }

                emit CollectionMTMinted(COID, amount);
            } else {
                CollectionMTs[COID] += CollectionPerMTAWMintedDiff << 128;
            }
        }
    }

    function getCollectionSettledInboxMT(
        uint256 COID
    ) public view returns (uint256 amount) {
        if (governance.getCollectionVault(COID) == address(0)) {
            amount = governance.getCollectionMintedMT(COID);
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
        uint256 AvatarMTAW = getCollectionAvatarMTAW(COID);

        if (
            CollectionPerMTAWMinted < PerMTAWMinted &&
            (CollectionMTAW > 0 || AvatarMTAW > 0)
        ) {
            inbox +=
                (((PerMTAWMinted - CollectionPerMTAWMinted) *
                    (CollectionMTAW + AvatarMTAW)) * 5) /
                100;
        }
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

    function addMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) public onlyAvatarOrMap {
        _addMTAW(avatarId, COID, LandId, amount);
    }

    function subMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId
    ) public onlyAvatarOrMap {
        _subMTAW(avatarId, COID, LandId);
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
        mintCollectionMT(COID);
        uint256 onMapMTAW = mintAvatarMT(avatarId, LandId);
        if (onMapMTAW == 0) {
            governance.addCollectionOnMapNum(COID);
        }
        settleCollectionMTAW(COID);

        MTProduceData += amount;
        CollectionMTs[COID] += amount;
        AvatarMTs[avatarId] += amount;
    }

    /**
     * substruct on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId mopn Land Id
     */
    function _subMTAW(uint256 avatarId, uint256 COID, uint32 LandId) internal {
        settlePerMTAWMinted();
        mintCollectionMT(COID);
        uint256 amount = mintAvatarMT(avatarId, LandId);
        governance.subCollectionOnMapNum(COID);
        settleCollectionMTAW(COID);

        MTProduceData -= amount;
        CollectionMTs[COID] -= amount;
        AvatarMTs[avatarId] -= amount;
    }

    function settleCollectionMTAW(uint256 COID) internal {
        uint256 point = getCollectionPoint(COID);
        uint256 collectionMTAW;
        if (point > 0) {
            collectionMTAW = point * governance.getCollectionOnMapNum(COID);
        }
        uint256 preCollectionMTAW = getCollectionMTAW(COID);
        if (collectionMTAW != preCollectionMTAW) {
            if (collectionMTAW > preCollectionMTAW) {
                MTProduceData += collectionMTAW - preCollectionMTAW;
                CollectionMTs[COID] += ((collectionMTAW - preCollectionMTAW) <<
                    64);
            } else {
                MTProduceData -= preCollectionMTAW;
                MTProduceData += collectionMTAW;
                CollectionMTs[COID] -= ((preCollectionMTAW - collectionMTAW) <<
                    64);
            }
        }
    }

    function calcCollectionMTAW(uint256 COID) public onlyCollectionVault(COID) {
        settlePerMTAWMinted();
        mintCollectionMT(COID);
        settleCollectionMTAW(COID);
    }

    function NFTOfferAcceptNotify(uint256 price) public {
        NFTOfferCoefficient =
            ((totalMTPledge - price) * NFTOfferCoefficient) /
            totalMTPledge;
    }

    function changeTotalMTPledge(
        uint256 COID,
        bool increase,
        uint256 amount
    ) public onlyCollectionVault(COID) {
        if (increase) {
            totalMTPledge += amount;
        } else {
            totalMTPledge -= amount;
        }
    }

    function gettimestamp() public view returns (uint256) {
        return block.timestamp;
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
