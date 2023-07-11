// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./libraries/TileMath.sol";
import "./erc6551/interfaces/IERC6551Account.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IMOPNData.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MOPNData is IMOPNData, Multicall {
    uint256 public constant MTOutputPerSec = 500000000;

    uint256 public constant MTProduceReduceInterval = 604800;

    uint256 public immutable MTProduceStartTimestamp;

    /// @notice uint96 MTTotalMinted + uint32 LastTickTimestamp + uint64 PerNFTPointMinted + uint64 TotalNFTPoints
    uint256 public MiningData1;

    /// @notice uint64 AdditionalFinishSnapshot + uint64 TotalAdditionalNFTPoints + uint64 NFTOfferCoefficient + uint64 TotalMTStaking
    uint256 public MiningData2;

    /// @notice  uint64 settled MT + uint64 PerCollectionNFTMinted  + uint64 PerNFTPointMinted + uint32 TotalNFTPoints + uint32 coordinate
    mapping(address => uint256) public AccountsData;

    /// @notice uint64 PerCollectionNFTMinted + uint64 PerNFTPointMinted + uint64 CollectionNFTPoints + uint32 additionalNFTPoints + uint32 AvatarNFTPoints
    mapping(address => uint256) public CollectionsData1;

    /**
     * @notice record the collection's states info
     * Collection address => uint32 additionalNFTPoint + uint64 mintedMT + uint32 registered account num + uint32 on map nft number
     */
    mapping(address => uint256) public CollectionsData2;

    /// @notice uint64 settled MT + uint64 totalMTMinted + uint64 OnLandMiningNFT
    mapping(uint32 => uint256) public LandHolderMTs;

    IMOPNGovernance public governance;

    constructor(address governance_, uint256 MTProduceStartTimestamp_) {
        MTProduceStartTimestamp = MTProduceStartTimestamp_;
        governance = IMOPNGovernance(governance_);
        MiningData2 = (10 ** 18) << 64;
    }

    function MTTotalMinted() public view returns (uint256) {
        return uint96(MiningData1 >> 160);
    }

    /**
     * @notice get last per mopn token allocation weight minted settlement timestamp
     */
    function LastTickTimestamp() public view returns (uint256) {
        return uint32(MiningData1 >> 128);
    }

    /**
     * @notice get settled Per MT Allocation Weight minted mopn token number
     */
    function PerNFTPointMinted() public view returns (uint256) {
        return uint64(MiningData1 >> 64);
    }

    /**
     * @notice get total mopn token allocation weights
     */
    function TotalNFTPoints() public view returns (uint256) {
        return uint64(MiningData1);
    }

    function AdditionalFinishSnapshot() public view returns (uint256) {
        return uint48(MiningData2 >> 192);
    }

    function TotalAdditionalNFTPoints() public view returns (uint256) {
        return uint64(MiningData2 >> 128);
    }

    function NFTOfferCoefficient() public view returns (uint256) {
        return uint64(MiningData2 >> 64);
    }

    function TotalMTStaking() public view returns (uint256) {
        return uint64(MiningData2);
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
        if (block.timestamp > LastTickTimestamp()) {
            uint256 PerNFTPointMintDiff = calcPerNFTPointMinted() -
                PerNFTPointMinted();
            MiningData1 +=
                ((PerNFTPointMintDiff * TotalNFTPoints()) << 160) |
                ((block.timestamp - LastTickTimestamp()) << 128) |
                ((PerNFTPointMintDiff) << 64);
        }
    }

    function closeWhiteList() public onlyGovernance {
        settlePerNFTPointMinted();
        MiningData2 += PerNFTPointMinted() << 192;
        MiningData1 -= TotalAdditionalNFTPoints();
    }

    function calcPerNFTPointMinted() public view returns (uint256) {
        if (MTProduceStartTimestamp > block.timestamp) {
            return 0;
        }
        uint256 totalNFTPoints = TotalNFTPoints();
        uint256 perNFTPointMinted = PerNFTPointMinted();
        if (totalNFTPoints > 0) {
            uint256 lastTickTimestamp = LastTickTimestamp();
            if (MTProduceStartTimestamp > lastTickTimestamp) {
                lastTickTimestamp = MTProduceStartTimestamp;
            }
            uint256 reduceTimes = (lastTickTimestamp -
                MTProduceStartTimestamp) / MTProduceReduceInterval;
            uint256 nextReduceTimestamp = MTProduceStartTimestamp +
                MTProduceReduceInterval +
                reduceTimes *
                MTProduceReduceInterval;

            while (true) {
                if (block.timestamp > nextReduceTimestamp) {
                    perNFTPointMinted +=
                        ((nextReduceTimestamp - lastTickTimestamp) *
                            currentMTPPS(reduceTimes)) /
                        totalNFTPoints;
                    lastTickTimestamp = nextReduceTimestamp;
                    reduceTimes++;
                    nextReduceTimestamp += MTProduceReduceInterval;
                } else {
                    perNFTPointMinted +=
                        ((block.timestamp - lastTickTimestamp) *
                            currentMTPPS(reduceTimes)) /
                        totalNFTPoints;
                    break;
                }
            }
        }
        return perNFTPointMinted;
    }

    function getAccountCollection(
        address account
    ) public view returns (address collectionAddress) {
        (, collectionAddress, ) = IERC6551Account(payable(account)).token();
    }

    /**
     * @notice get avatar settled unclaimed minted mopn token
     * @param account account wallet address
     */
    function getAccountSettledMT(
        address account
    ) public view returns (uint256) {
        return uint64(AccountsData[account] >> 192);
    }

    function getAccountPerCollectionNFTMinted(
        address account
    ) public view returns (uint256) {
        return uint64(AccountsData[account] >> 128);
    }

    /**
     * @notice get avatar settled per mopn token allocation weight minted mopn token number
     * @param account account wallet address
     */
    function getAccountPerNFTPointMinted(
        address account
    ) public view returns (uint256) {
        return uint64(AccountsData[account] >> 64);
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param account account wallet address
     */
    function getAccountTotalNFTPoint(
        address account
    ) public view returns (uint256) {
        return uint32(AccountsData[account] >> 32);
    }

    function getAccountCoordinate(
        address account
    ) public view returns (uint32) {
        return uint32(AccountsData[account]);
    }

    function setAccountCoordinate(
        address account,
        uint32 coordinate
    ) public onlyMOPNOrBomb {
        AccountsData[account] =
            AccountsData[account] -
            getAccountCoordinate(account) +
            coordinate;
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param account account wallet address
     */
    function calcAccountMT(
        address account
    ) public view returns (uint256 inbox) {
        inbox = getAccountSettledMT(account);
        uint256 AccountTotalNFTPoint = getAccountTotalNFTPoint(account);
        uint256 AccountPerNFTPointMintedDiff = calcPerNFTPointMinted() -
            getAccountPerNFTPointMinted(account);

        if (AccountPerNFTPointMintedDiff > 0 && AccountTotalNFTPoint > 0) {
            address collectionAddress = getAccountCollection(account);
            uint256 AccountPerCollectionNFTMintedDiff = getPerCollectionNFTMinted(
                    collectionAddress
                ) - getAccountPerCollectionNFTMinted(account);
            inbox +=
                ((AccountPerNFTPointMintedDiff * AccountTotalNFTPoint) * 90) /
                100;
            if (AccountPerCollectionNFTMintedDiff > 0) {
                inbox += (AccountPerCollectionNFTMintedDiff * 90) / 100;
            }
        }
    }

    /**
     * @notice mint avatar mopn token
     * @param account account wallet address
     */
    function mintAccountMT(address account) public returns (uint256) {
        uint256 AccountTotalNFTPoint = getAccountTotalNFTPoint(account);
        uint256 AccountPerNFTPointMintedDiff = PerNFTPointMinted() -
            getAccountPerNFTPointMinted(account);
        if (AccountPerNFTPointMintedDiff <= 0) {
            return AccountTotalNFTPoint;
        }

        uint256 AccountPerCollectionNFTMintedDiff = getPerCollectionNFTMinted(
            getAccountCollection(account)
        ) - getAccountPerCollectionNFTMinted(account);

        uint256 amount;
        if (AccountTotalNFTPoint > 0) {
            amount =
                AccountPerNFTPointMintedDiff *
                AccountTotalNFTPoint +
                (
                    AccountPerCollectionNFTMintedDiff > 0
                        ? AccountPerCollectionNFTMintedDiff
                        : 0
                );

            uint32 LandId = IMOPN(governance.mopnContract()).getTileLandId(
                getAccountCoordinate(account)
            );
            uint256 landamount = (amount * 5) / 100;
            LandHolderMTs[LandId] += (landamount << 128) | (landamount << 64);
            emit LandHolderMTMinted(LandId, landamount);

            amount = (amount * 90) / 100;

            AccountsData[account] += amount << 192;
            emit AccountMTMinted(account, amount);
        }
        AccountsData[account] +=
            (AccountPerCollectionNFTMintedDiff << 128) |
            (AccountPerNFTPointMintedDiff << 64);

        return AccountTotalNFTPoint;
    }

    /**
     * @notice redeem account unclaimed minted mopn token
     * @param account account wallet address
     */
    function claimAccountMT(
        address account
    ) public onlyMT returns (uint256 amount) {
        settlePerNFTPointMinted();
        mintCollectionMT(getAccountCollection(account));
        mintAccountMT(account);

        amount = getAccountSettledMT(account);
        if (amount > 0) {
            AccountsData[account] -= amount << 192;
        }
    }

    function getPerCollectionNFTMinted(
        address collectionAddress
    ) public view returns (uint256) {
        return uint64(CollectionsData1[collectionAddress] >> 192);
    }

    /**
     * @notice get collection settled per mopn token allocation weight minted mopn token number
     * @param collectionAddress collection contract address
     */
    function getCollectionPerNFTPointMinted(
        address collectionAddress
    ) public view returns (uint256) {
        return uint64(CollectionsData1[collectionAddress] >> 128);
    }

    /**
     * @notice get collection on map mining mopn token allocation weight
     * @param collectionAddress collection contract adddress
     */
    function getCollectionNFTPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return uint64(CollectionsData1[collectionAddress] >> 64);
    }

    function getCollectionAdditionalNFTPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return uint32(CollectionsData1[collectionAddress] >> 32);
    }

    function getCollectionAvatarNFTPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return uint32(CollectionsData1[collectionAddress]);
    }

    function getCollectionAdditionalNFTPoint(
        address collectionAddress
    ) public view returns (uint256) {
        return uint32(CollectionsData2[collectionAddress] >> 128);
    }

    function setCollectionAdditionalNFTPoint(
        address collectionAddress,
        uint256 additionalNFTPoint
    ) public onlyMOPNOrBomb {
        CollectionsData2[collectionAddress] =
            (additionalNFTPoint << 128) |
            uint128(CollectionsData2[collectionAddress]);
    }

    function getCollectionSettledMT(
        address collectionAddress
    ) public view returns (uint256) {
        return uint64(CollectionsData2[collectionAddress] >> 64);
    }

    /**
     * @notice get NFT collection minted avatar number
     * @param collectionAddress collection contract address
     */
    function getCollectionAvatarNum(
        address collectionAddress
    ) public view returns (uint256) {
        return uint32(CollectionsData2[collectionAddress] >> 32);
    }

    function addCollectionAvatarNum(
        address collectionAddress
    ) public onlyMOPNOrBomb {
        CollectionsData2[collectionAddress] += uint256(1) << 32;
    }

    /**
     * @notice get NFT collection On map avatar number
     * @param collectionAddress collection contract address
     */
    function getCollectionOnMapNum(
        address collectionAddress
    ) public view returns (uint256) {
        return uint32(CollectionsData2[collectionAddress]);
    }

    function addCollectionOnMapNum(address collectionAddress) internal {
        CollectionsData2[collectionAddress]++;
    }

    function subCollectionOnMapNum(address collectionAddress) internal {
        CollectionsData2[collectionAddress]--;
    }

    function getCollectionPoint(
        address collectionAddress
    ) public view returns (uint256 point) {
        if (governance.getCollectionVault(collectionAddress) != address(0)) {
            point =
                IMOPNToken(governance.mtContract()).balanceOf(
                    governance.getCollectionVault(collectionAddress)
                ) /
                10 ** 8;
        }
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param collectionAddress collection contract address
     */
    function calcCollectionMT(
        address collectionAddress
    ) public view returns (uint256 inbox) {
        inbox = getCollectionSettledMT(collectionAddress);
        uint256 perNFTPointMinted = calcPerNFTPointMinted();
        uint256 CollectionPerNFTPointMinted = getCollectionPerNFTPointMinted(
            collectionAddress
        );
        uint256 WhiteListNFTPoints = getCollectionAdditionalNFTPoints(
            collectionAddress
        );
        uint256 CollectionNFTPoints = getCollectionNFTPoints(collectionAddress);
        uint256 AvatarNFTPoints = getCollectionAvatarNFTPoints(
            collectionAddress
        );

        if (
            CollectionPerNFTPointMinted < perNFTPointMinted &&
            AvatarNFTPoints > 0
        ) {
            inbox +=
                (((perNFTPointMinted - CollectionPerNFTPointMinted) *
                    (CollectionNFTPoints + AvatarNFTPoints)) * 5) /
                100;
            if (WhiteListNFTPoints > 0) {
                if (AdditionalFinishSnapshot() > 0) {
                    inbox +=
                        (((AdditionalFinishSnapshot() -
                            CollectionPerNFTPointMinted) * WhiteListNFTPoints) *
                            5) /
                        100;
                } else {
                    inbox +=
                        (((perNFTPointMinted - CollectionPerNFTPointMinted) *
                            WhiteListNFTPoints) * 5) /
                        100;
                }
            }
        }
    }

    /**
     * @notice mint collection mopn token
     * @param collectionAddress collection contract address
     */
    function mintCollectionMT(address collectionAddress) public {
        uint256 CollectionPerNFTPointMinted = getCollectionPerNFTPointMinted(
            collectionAddress
        );
        uint256 CollectionPerNFTPointMintedDiff = PerNFTPointMinted() -
            CollectionPerNFTPointMinted;
        if (CollectionPerNFTPointMintedDiff > 0) {
            uint256 AvatarNFTPoints = getCollectionAvatarNFTPoints(
                collectionAddress
            );
            if (AvatarNFTPoints > 0) {
                uint256 CollectionData1 = CollectionsData1[collectionAddress];

                uint256 amount = ((CollectionPerNFTPointMintedDiff *
                    AvatarNFTPoints) * 5) / 100;
                CollectionData1 += CollectionPerNFTPointMintedDiff << 128;

                uint256 CollectionNFTPoints = getCollectionNFTPoints(
                    collectionAddress
                );
                if (CollectionNFTPoints > 0) {
                    amount +=
                        ((CollectionPerNFTPointMintedDiff *
                            CollectionNFTPoints) * 5) /
                        100;
                    CollectionData1 +=
                        ((CollectionPerNFTPointMintedDiff *
                            CollectionNFTPoints) /
                            getCollectionOnMapNum(collectionAddress)) <<
                        192;
                }

                uint256 WhiteListNFTPoints = getCollectionAdditionalNFTPoints(
                    collectionAddress
                );
                if (WhiteListNFTPoints > 0) {
                    uint256 whiteListFinPerNFTPointMinted = AdditionalFinishSnapshot();
                    if (whiteListFinPerNFTPointMinted > 0) {
                        if (
                            whiteListFinPerNFTPointMinted >
                            CollectionPerNFTPointMinted
                        ) {
                            amount = ((((whiteListFinPerNFTPointMinted -
                                CollectionPerNFTPointMinted) *
                                WhiteListNFTPoints) * 5) / 100);
                            CollectionData1 +=
                                (((whiteListFinPerNFTPointMinted -
                                    CollectionPerNFTPointMinted) *
                                    WhiteListNFTPoints) /
                                    getCollectionOnMapNum(collectionAddress)) <<
                                192;
                            CollectionData1 -= WhiteListNFTPoints << 32;
                        }
                    } else {
                        amount += (((CollectionPerNFTPointMintedDiff *
                            WhiteListNFTPoints) * 5) / 100);
                        CollectionData1 +=
                            (((CollectionPerNFTPointMintedDiff) *
                                WhiteListNFTPoints) /
                                getCollectionOnMapNum(collectionAddress)) <<
                            192;
                    }
                }

                CollectionsData1[collectionAddress] = CollectionData1;
                CollectionsData2[collectionAddress] += amount << 64;
                emit CollectionMTMinted(collectionAddress, amount);
            } else {
                CollectionsData1[collectionAddress] +=
                    CollectionPerNFTPointMintedDiff <<
                    128;
            }
        }
    }

    function claimCollectionMT(address collectionAddress) public {
        uint256 amount = getCollectionSettledMT(collectionAddress);
        if (amount > 0) {
            address collectionVault = governance.getCollectionVault(
                collectionAddress
            );
            if (collectionVault == address(0)) {
                collectionVault = governance.createCollectionVault(
                    collectionAddress
                );
            }
            governance.mintMT(collectionVault, amount);
            CollectionsData2[collectionAddress] -= amount << 64;
            MiningData2 += amount;
        }
    }

    function settleCollectionNFTPoint(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) {
        _settleCollectionNFTPoint(collectionAddress);

        emit SettleCollectionNFTPoint(collectionAddress);
    }

    function _settleCollectionNFTPoint(address collectionAddress) internal {
        uint256 point = getCollectionPoint(collectionAddress);
        uint256 collectionNFTPoint;
        if (point > 0) {
            collectionNFTPoint =
                point *
                getCollectionOnMapNum(collectionAddress);
        }
        uint256 preCollectionNFTPoint = getCollectionNFTPoints(
            collectionAddress
        );

        if (collectionNFTPoint > preCollectionNFTPoint) {
            MiningData1 += collectionNFTPoint - preCollectionNFTPoint;
            CollectionsData1[collectionAddress] += ((collectionNFTPoint -
                preCollectionNFTPoint) << 64);
        } else if (collectionNFTPoint < preCollectionNFTPoint) {
            MiningData1 -= preCollectionNFTPoint - collectionNFTPoint;
            CollectionsData1[collectionAddress] -= ((preCollectionNFTPoint -
                collectionNFTPoint) << 64);
        }

        uint256 additionalpoint = getCollectionAdditionalNFTPoint(
            collectionAddress
        );
        uint256 collectionAdditionalNFTPoint;
        if (additionalpoint > 0) {
            collectionAdditionalNFTPoint =
                additionalpoint *
                getCollectionOnMapNum(collectionAddress);
        }
        uint256 preCollectionAdditionalNFTPoint = getCollectionAdditionalNFTPoints(
                collectionAddress
            );

        if (collectionAdditionalNFTPoint > preCollectionAdditionalNFTPoint) {
            MiningData1 +=
                collectionAdditionalNFTPoint -
                preCollectionAdditionalNFTPoint;
            CollectionsData1[
                collectionAddress
            ] += ((collectionAdditionalNFTPoint -
                preCollectionAdditionalNFTPoint) << 32);
        } else if (
            collectionAdditionalNFTPoint < preCollectionAdditionalNFTPoint
        ) {
            MiningData1 -=
                preCollectionAdditionalNFTPoint -
                collectionAdditionalNFTPoint;
            CollectionsData1[
                collectionAddress
            ] -= ((preCollectionAdditionalNFTPoint -
                collectionAdditionalNFTPoint) << 32);
        }
    }

    function settleCollectionMining(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) {
        settlePerNFTPointMinted();
        mintCollectionMT(collectionAddress);
        claimCollectionMT(collectionAddress);
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
        address account,
        uint256 amount
    ) public onlyMOPNOrBomb {
        _addNFTPoint(account, amount);
    }

    function subNFTPoint(
        address account,
        uint256 amount
    ) public onlyMOPNOrBomb {
        _subNFTPoint(account, amount);
    }

    /**
     * add on map mining mopn token allocation weight
     * @param account account wallet address
     * @param amount Points amount
     */
    function _addNFTPoint(address account, uint256 amount) internal {
        amount *= 100;
        settlePerNFTPointMinted();
        address collectionAddress = getAccountCollection(account);
        mintCollectionMT(collectionAddress);
        uint256 exist = mintAccountMT(account);
        if (exist == 0) {
            addCollectionOnMapNum(collectionAddress);
        }

        _settleCollectionNFTPoint(collectionAddress);

        MiningData1 += amount;
        CollectionsData1[collectionAddress] += amount;
        AccountsData[account] += amount;
    }

    /**
     * substruct on map mining mopn token allocation weight
     * @param account account wallet address
     */
    function _subNFTPoint(address account, uint256 amount) internal {
        settlePerNFTPointMinted();
        address collectionAddress = getAccountCollection(account);
        mintCollectionMT(collectionAddress);
        if (amount == 0) {
            amount = mintAccountMT(account);
            subCollectionOnMapNum(collectionAddress);
        } else {
            mintAccountMT(account);
        }

        _settleCollectionNFTPoint(collectionAddress);

        MiningData1 -= amount;
        CollectionsData1[collectionAddress] -= amount;
        AccountsData[account] -= amount;
    }

    function NFTOfferAcceptNotify(
        address collectionAddress,
        uint256 price,
        uint256 tokenId
    ) public onlyCollectionVault(collectionAddress) {
        uint256 totalMTStaking = TotalMTStaking();
        MiningData2 =
            (AdditionalFinishSnapshot() << 192) |
            ((((totalMTStaking + 10000 - price) * NFTOfferCoefficient()) /
                totalMTStaking +
                10000) << 64) |
            totalMTStaking;
        emit NFTOfferAccept(collectionAddress, tokenId, price);
    }

    function NFTAuctionAcceptNotify(
        address collectionAddress,
        uint256 price,
        uint256 tokenId
    ) public {
        emit NFTAuctionAccept(collectionAddress, tokenId, price);
    }

    function changeTotalMTStaking(
        address collectionAddress,
        bool increase,
        uint256 amount
    ) public onlyCollectionVault(collectionAddress) {
        if (increase) {
            MiningData2 += amount;
        } else {
            MiningData2 -= amount;
        }
    }

    modifier onlyCollectionVault(address collectionAddress) {
        require(
            msg.sender == governance.getCollectionVault(collectionAddress),
            "only collection vault allowed"
        );
        _;
    }

    modifier onlyMOPNOrBomb() {
        require(
            msg.sender == governance.bombContract() ||
                msg.sender == governance.mopnContract(),
            "only mopn or bomb allowed"
        );
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "only governance allowed");
        _;
    }

    modifier onlyMT() {
        require(
            msg.sender == governance.mtContract(),
            "only mopn token allowed"
        );
        _;
    }
}
