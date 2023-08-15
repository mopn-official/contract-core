// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./erc6551/interfaces/IERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IMOPNCollectionVault.sol";
import "./libraries/TileMath.sol";
import "./libraries/MOPNBitMap.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/

/// @title MOPN Contract
/// @author Cyanface <cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract MOPN is IMOPN, Multicall, Ownable {
    using MOPNBitMap for uint256;

    uint256 public MTOutputPerSec;
    uint256 public MTStepStartTimestamp;

    uint256 public immutable MTReduceInterval;
    uint256 public immutable MaxCollectionOnMapNum;
    uint256 public immutable MaxCollectionMOPNPoint;

    /// Tile => uint24 CollectionIndex uint160 account + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    /// @notice uint64 MTTotalMinted + uint32 LastTickTimestamp + uint48 TotalAdditionalMOPNPoints + uint64 TotalMOPNPoints + uint48 PerMOPNPointMinted
    uint256 public MiningData;

    /// @notice uint48 AdditionalFinishSnapshot + uint48 NFTOfferCoefficient + uint48 TotalCollectionClaimed + uint64 TotalMTStaking + uint24 CollectionIndex
    uint256 public MiningDataExt;

    /// @notice  uint24 CollectionIndex + uint48 SettledMT + uint48 PerCollectionNFTMintedSnapshot  + uint48 PerMOPNPointMintedSnapshot + uint32 coordinate
    mapping(address => uint256) public AccountsData;

    /// @notice uint24 CollectionIndex + uint48 SettledMT + uint48 PerCollectionNFTMinted + uint48 PerMOPNPointMintedSnapshot + uint24 CollectionMOPNPoint
    ///         + uint16 AdditionalMOPNPoint + uint16 OnMapNftNumber + uint32 OnMapMOPNPoints
    mapping(address => uint256) public CollectionsData;

    /// @notice uint160 account address + uint48 SettledMT
    mapping(uint32 => uint256) public LandIdMTs;

    mapping(uint256 => address) public CollectionIndexMap;

    IMOPNGovernance public governance;

    constructor(
        address governance_,
        uint256 MTOutputPerSec_,
        uint32 MTStepStartTimestamp_,
        uint32 MTReduceInterval_,
        uint256 MaxCollectionOnMapNum_,
        uint256 MaxCollectionMOPNPoint_
    ) {
        governance = IMOPNGovernance(governance_);
        MTOutputPerSec = MTOutputPerSec_;
        MTStepStartTimestamp = MTStepStartTimestamp_;
        MTReduceInterval = MTReduceInterval_;
        MaxCollectionOnMapNum = MaxCollectionOnMapNum_;
        MaxCollectionMOPNPoint = MaxCollectionMOPNPoint_;
        MiningData = MTStepStartTimestamp_ << 160;
        MiningDataExt = (10 ** 14) << 136;
    }

    function getGovernance() public view returns (address) {
        return address(governance);
    }

    function getPreProcessData(
        address account
    )
        public
        returns (
            address collectionAddress,
            uint256 mData,
            uint256 cData,
            uint256 aData
        )
    {
        if (AccountsData[account] > 0) {
            collectionAddress = CollectionIndexMap[
                AccountsData[account].AccountCollectionIndex()
            ];
        } else {
            require(
                IERC165(payable(account)).supportsInterface(
                    type(IERC6551Account).interfaceId
                ),
                "not erc6551 account"
            );

            (
                uint256 chainId,
                address collectionAddress_,
                uint256 tokenId
            ) = IERC6551Account(payable(account)).token();

            require(
                chainId == block.chainid,
                "not support cross chain account"
            );

            collectionAddress = collectionAddress_;
            require(
                account ==
                    IERC6551Registry(governance.ERC6551Registry()).account(
                        governance.ERC6551AccountProxy(),
                        chainId,
                        collectionAddress,
                        tokenId,
                        0
                    ),
                "not a mopn Account Implementation"
            );
        }

        mData = settlePerMOPNPointMinted();
        cData = settleCollectionMT(collectionAddress, mData);
        aData = settleAccountMT(msg.sender, cData);

        if (cData.CollectionIndex() == 0) {
            MiningDataExt++;
            CollectionIndexMap[
                MiningDataExt.CurrentCollectionIndex()
            ] = collectionAddress;
            cData += MiningDataExt.CurrentCollectionIndex() << 232;
        }

        if (aData.AccountCollectionIndex() == 0) {
            aData += cData.CollectionIndex() << 176;
        }
    }

    uint32[] neighbors = [9999, 1, 10000, 9999, 1, 10000];

    function neighbor(
        uint32 tileCoordinate,
        uint256 direction
    ) public view returns (uint32) {
        if (direction < 1 || direction > 3) {
            return tileCoordinate + neighbors[direction];
        }
        return tileCoordinate - neighbors[direction];
    }

    /**
     * @notice an on map avatar move to a new tile
     * @param tileCoordinate NFT move To coordinate
     */
    function moveTo(uint32 tileCoordinate, uint32 LandId) public {
        require(block.timestamp > MTStepStartTimestamp, "mopn is not open yet");

        require(tiles[tileCoordinate].TileAccountInt() == 0, "dst Occupied");

        if (LandId == 0 || tiles[tileCoordinate].TileLandId() != LandId) {
            require(
                TileMath.distance(
                    tileCoordinate,
                    TileMath.LandCenterTile(LandId)
                ) < 6,
                "LandId error"
            );
            require(
                IMOPNLand(governance.landContract()).nextTokenId() > LandId,
                "Land Not Open"
            );
        }

        (
            address collectionAddress,
            uint256 mData,
            uint256 cData,
            uint256 aData
        ) = getPreProcessData(msg.sender);

        uint256 msgsender = uint160(msg.sender);

        bool collectionLinked = true;
        ++tileCoordinate;
        for (uint256 i = 0; i < 18; i++) {
            uint256 tileData = tiles[tileCoordinate];

            if (tileData.TileCollectionIndex() > 0) {
                require(
                    tileData.TileCollectionIndex() == cData.CollectionIndex(),
                    "tile has enemy"
                );
                collectionLinked = true;
            }

            if (i == 5) {
                tileCoordinate += 10001;
            } else if (i < 5) {
                tileCoordinate = neighbor(tileCoordinate, i);
            } else {
                tileCoordinate = neighbor(tileCoordinate, (i - 6) / 2);
            }
        }
        tileCoordinate -= 2;

        uint32 orgTileCoordinate = aData.AccountCoordinate();
        if (collectionLinked == false) {
            require(
                cData.CollectionOnMapNum() == 0 ||
                    (orgTileCoordinate > 0 && cData.CollectionOnMapNum() == 1),
                "linked avatar missing"
            );
        }

        uint256 tileMOPNPoint = TileMath.getTileMOPNPoint(tileCoordinate) * 100;
        if (orgTileCoordinate > 0) {
            tiles[orgTileCoordinate] = tiles[orgTileCoordinate].TileLandId();
            uint256 orgMOPNPoint = TileMath.getTileMOPNPoint(
                orgTileCoordinate
            ) * 100;

            if (tileMOPNPoint > orgMOPNPoint) {
                tileMOPNPoint -= orgMOPNPoint;
                cData += tileMOPNPoint;
                mData += tileMOPNPoint << 48;
            } else if (tileMOPNPoint < orgMOPNPoint) {
                tileMOPNPoint = orgMOPNPoint - tileMOPNPoint;
                cData -= tileMOPNPoint;
                mData -= tileMOPNPoint << 48;
            }
            aData = aData - orgTileCoordinate + tileCoordinate;

            emit AccountMove(
                msg.sender,
                LandId,
                orgTileCoordinate,
                tileCoordinate
            );
        } else {
            require(
                cData.CollectionOnMapNum() < MaxCollectionOnMapNum,
                "collection on map nft number overflow"
            );

            tileMOPNPoint +=
                IMOPNBomb(governance.bombContract()).balanceOf(msg.sender, 2) *
                100;

            cData += (uint256(1) << 32) | tileMOPNPoint;
            mData +=
                (cData.CollectionAdditionalMOPNPoint() << 112) |
                ((tileMOPNPoint +
                    cData.CollectionMOPNPoint() +
                    cData.CollectionAdditionalMOPNPoint()) << 48);
            aData += tileCoordinate;

            emit AccountJumpIn(msg.sender, LandId, tileCoordinate);
        }

        tiles[tileCoordinate] =
            (cData.CollectionIndex() << 192) |
            (msgsender << 32) |
            uint256(LandId);
        MiningData = mData;
        CollectionsData[collectionAddress] = cData;
        AccountsData[msg.sender] = aData;
    }

    /**
     * @notice throw a bomb to a tile
     * @param tileCoordinate bomb to tile coordinate
     */
    function bomb(uint32 tileCoordinate) public {
        // address collectionAddress = getQualifiedAccountCollection(msg.sender);
        // uint256 mData = settlePerMOPNPointMinted();
        // uint256 cData = settleCollectionMT(collectionAddress, mData);
        // uint256 aData = settleAccountMT(msg.sender, cData);
        // require(aData.AccountCoordinate() > 0, "NFT not on the map");
        // address[] memory attackAccounts = new address[](7);
        // uint32[] memory victimsCoordinates = new uint32[](7);
        // uint32 orgTileCoordinate = tileCoordinate;
        // uint256 killed;
        // for (uint256 i = 0; i < 7; i++) {
        //     address attackAccount = tiles[tileCoordinate].TileAccount();
        //     if (attackAccount != address(0) && attackAccount != msg.sender) {
        //         //remove tile account
        //         tiles[tileCoordinate] = tiles[tileCoordinate].TileLandId();
        //         //remove account tile
        //         attackAccounts[i] = attackAccount;
        //         victimsCoordinates[i] = tileCoordinate;
        //         address kcollectionAddress = getAccountCollection(
        //             attackAccount
        //         );
        //         uint256 kcData = settleCollectionMT(kcollectionAddress, mData);
        //         uint256 kaData = settleAccountMT(attackAccount, kcData);
        //         uint256 accountOnMapMOPNPoint = getAccountOnMapMOPNPoint(
        //             attackAccount
        //         );
        //         mData -=
        //             (kcData.CollectionAdditionalMOPNPoint() << 112) |
        //             ((accountOnMapMOPNPoint +
        //                 kcData.CollectionAdditionalMOPNPoint() +
        //                 kcData.CollectionMOPNPoint()) << 48);
        //         kcData -= (uint256(1) << 32) | accountOnMapMOPNPoint;
        //         kaData -= kaData.AccountCoordinate();
        //         CollectionsData[kcollectionAddress] = kcData;
        //         AccountsData[attackAccount] = kaData;
        //         killed++;
        //     }
        //     if (i == 0) {
        //         ++tileCoordinate;
        //     } else {
        //         tileCoordinate = neighbor(tileCoordinate, i - 1);
        //     }
        // }
        // governance.burnBomb(msg.sender, 1, killed);
        // if (killed > 0) {
        //     killed *= 100;
        //     cData += killed;
        //     mData += killed << 48;
        // }
        // MiningData = mData;
        // CollectionsData[collectionAddress] = cData;
        // AccountsData[msg.sender] = aData;
        // emit BombUse(
        //     msg.sender,
        //     orgTileCoordinate,
        //     attackAccounts,
        //     victimsCoordinates
        // );
    }

    function gettData(uint32 coordinate) public view returns (uint256) {
        return tiles[coordinate];
    }

    function getmData() public view returns (uint256) {
        return MiningData;
    }

    function getmDataExt() public view returns (uint256) {
        return MiningDataExt;
    }

    function getcData(address collectionAddress) public view returns (uint256) {
        return CollectionsData[collectionAddress];
    }

    function getaData(address account) public view returns (uint256) {
        return AccountsData[account];
    }

    /**
     * get current mt produce per second
     * @param reduceTimes reduce times
     */
    function currentMTPPS(
        uint256 reduceTimes
    ) public view returns (uint256 MTPPB) {
        int128 reducePercentage = ABDKMath64x64.divu(997, 1000);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, MTOutputPerSec);
    }

    function currentMTPPS() public view returns (uint256 MTPPB) {
        if (MTStepStartTimestamp > block.timestamp) {
            return 0;
        }
        return currentMTPPS(MTReduceTimes());
    }

    function MTReduceTimes() public view returns (uint256) {
        return (block.timestamp - MTStepStartTimestamp) / MTReduceInterval;
    }

    /**
     * @notice settle per mopn token allocation weight minted mopn token
     */
    function settlePerMOPNPointMinted() public returns (uint256 mData) {
        mData = MiningData;
        uint256 LastTickTimestamp_ = mData.LastTickTimestamp();
        if (block.timestamp > LastTickTimestamp_) {
            uint256 reduceTimes = MTReduceTimes();
            if (mData.TotalMOPNPoints() > 0) {
                uint256 perMOPNPointMinted;
                if (reduceTimes == 0) {
                    perMOPNPointMinted +=
                        ((block.timestamp - LastTickTimestamp_) *
                            MTOutputPerSec) /
                        mData.TotalMOPNPoints();
                } else {
                    uint256 nextReduceTimestamp = MTStepStartTimestamp +
                        MTReduceInterval;
                    for (uint256 i = 0; i <= reduceTimes; i++) {
                        perMOPNPointMinted +=
                            ((nextReduceTimestamp - LastTickTimestamp_) *
                                currentMTPPS(i)) /
                            mData.TotalMOPNPoints();
                        mData +=
                            (nextReduceTimestamp - LastTickTimestamp_) <<
                            160;
                        nextReduceTimestamp += MTReduceInterval;
                        if (nextReduceTimestamp > block.timestamp) {
                            nextReduceTimestamp = block.timestamp;
                        }
                    }
                }
                mData +=
                    ((perMOPNPointMinted * mData.TotalMOPNPoints()) << 192) |
                    perMOPNPointMinted;
            }

            mData += (block.timestamp - LastTickTimestamp_) << 160;

            if (reduceTimes > 0) {
                MTOutputPerSec = currentMTPPS(reduceTimes);
                MTStepStartTimestamp += reduceTimes * MTReduceInterval;
            }
        }
    }

    function getCollectionMOPNPoint(
        address collectionAddress
    ) public view returns (uint256 point) {
        if (governance.getCollectionVault(collectionAddress) != address(0)) {
            point =
                IMOPNCollectionVault(
                    governance.getCollectionVault(collectionAddress)
                ).MTBalance() /
                10 ** 8;
        }
        if (point > MaxCollectionMOPNPoint) {
            point = MaxCollectionMOPNPoint;
        }
    }

    /**
     * @notice mint collection mopn token
     * @param collectionAddress collection contract address
     */
    //@todo privelege
    function settleCollectionMT(
        address collectionAddress,
        uint256 mData
    ) public returns (uint256 cData) {
        cData = CollectionsData[collectionAddress];
        uint256 perMOPNPointMintedDiff = mData.PerMOPNPointMinted() -
            cData.CollectionPerMOPNPointMinted();
        if (perMOPNPointMintedDiff > 0) {
            cData += perMOPNPointMintedDiff << 88;
            if (cData.CollectionOnMapMOPNPoints() > 0) {
                uint256 amount = ((perMOPNPointMintedDiff *
                    (cData.CollectionOnMapMOPNPoints() +
                        cData.CollectionMOPNPoints())) * 5) / 100;

                if (cData.CollectionMOPNPoints() > 0) {
                    cData +=
                        ((perMOPNPointMintedDiff *
                            cData.CollectionMOPNPoints()) /
                            cData.CollectionOnMapNum()) <<
                        136;
                }

                if (cData.CollectionAdditionalMOPNPoints() > 0) {
                    uint256 AdditionalFinishSnapshot_ = MiningDataExt
                        .AdditionalFinishSnapshot();
                    if (AdditionalFinishSnapshot_ > 0) {
                        if (
                            AdditionalFinishSnapshot_ >
                            cData.CollectionPerMOPNPointMinted()
                        ) {
                            amount +=
                                (((AdditionalFinishSnapshot_ -
                                    cData.CollectionPerMOPNPointMinted()) *
                                    cData.CollectionAdditionalMOPNPoints()) *
                                    5) /
                                100;
                            cData +=
                                (((AdditionalFinishSnapshot_ -
                                    cData.CollectionPerMOPNPointMinted()) *
                                    cData.CollectionAdditionalMOPNPoints()) /
                                    cData.CollectionOnMapNum()) <<
                                136;
                        }
                        cData -= cData.CollectionAdditionalMOPNPoint() << 48;
                    } else {
                        amount += (((perMOPNPointMintedDiff *
                            cData.CollectionAdditionalMOPNPoints()) * 5) / 100);
                        cData +=
                            (((cData.CollectionPerMOPNPointMinted()) *
                                cData.CollectionAdditionalMOPNPoints()) /
                                cData.CollectionOnMapNum()) <<
                            136;
                    }
                }

                cData += amount << 184;

                emit CollectionMTMinted(collectionAddress, amount);
            } else {
                if (
                    cData.CollectionAdditionalMOPNPoint() > 0 &&
                    MiningDataExt.AdditionalFinishSnapshot() > 0
                ) {
                    cData -= cData.CollectionAdditionalMOPNPoint() << 48;
                }
            }
        }
    }

    function claimCollectionMT(
        address collectionAddress,
        uint256 cData
    ) public returns (uint256 amount) {
        amount = cData.CollectionSettledMT();
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
            cData -= amount << 184;
            CollectionsData[collectionAddress] = cData;
            MiningDataExt += (amount << 88) | (amount << 24);
        }
    }

    function settleCollectionMOPNPoint(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) {
        uint256 point = getCollectionMOPNPoint(collectionAddress);
        uint256 lastPoint = uint24(CollectionsData[collectionAddress] >> 64);
        if (point != lastPoint) {
            uint256 collectionMOPNPoints = point *
                CollectionsData[collectionAddress].CollectionOnMapNum();

            uint256 preCollectionMOPNPoints = lastPoint *
                CollectionsData[collectionAddress].CollectionOnMapNum();

            if (collectionMOPNPoints > preCollectionMOPNPoints) {
                MiningData += collectionMOPNPoints - preCollectionMOPNPoints;
            } else if (collectionMOPNPoints < preCollectionMOPNPoints) {
                MiningData -= preCollectionMOPNPoints - collectionMOPNPoints;
            }

            CollectionsData[collectionAddress] =
                CollectionsData[collectionAddress] -
                (lastPoint << 64) +
                (point << 64);
        }
    }

    function settleCollectionMining(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) returns (uint256) {
        uint256 mData = settlePerMOPNPointMinted();
        uint256 cData = settleCollectionMT(collectionAddress, mData);
        return claimCollectionMT(collectionAddress, cData);
    }

    function accountClaimAvailable(address account) public view returns (bool) {
        return
            AccountsData[account].AccountSettledMT() > 0 ||
            AccountsData[account].AccountCoordinate() > 0;
    }

    function getAccountCollection(
        address account
    ) public view returns (address collectionAddress) {
        (, collectionAddress, ) = IERC6551Account(payable(account)).token();
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param account account wallet address
     */
    function getAccountOnMapMOPNPoint(
        address account
    ) public view returns (uint256 OnMapMOPNPoint) {
        uint32 coordinate = AccountsData[account].AccountCoordinate();
        if (coordinate > 0) {
            OnMapMOPNPoint =
                (TileMath.getTileMOPNPoint(coordinate) +
                    IMOPNBomb(governance.bombContract()).balanceOf(
                        account,
                        2
                    )) *
                100;
        }
    }

    /**
     * @notice mint avatar mopn token
     * @param account account wallet address
     */
    function settleAccountMT(
        address account,
        uint256 cData
    ) public returns (uint256 aData) {
        aData = AccountsData[account];
        uint256 perMOPNPointMintedDiff = cData.CollectionPerMOPNPointMinted() -
            aData.AccountPerMOPNPointMinted();

        if (perMOPNPointMintedDiff > 0) {
            if (aData.AccountCoordinate() > 0) {
                uint256 AccountOnMapMOPNPoint = getAccountOnMapMOPNPoint(
                    account
                );
                uint256 AccountPerCollectionNFTMintedDiff = cData
                    .PerCollectionNFTMinted() -
                    aData.AccountPerCollectionNFTMinted();

                uint256 amount = perMOPNPointMintedDiff *
                    AccountOnMapMOPNPoint +
                    (
                        AccountPerCollectionNFTMintedDiff > 0
                            ? AccountPerCollectionNFTMintedDiff
                            : 0
                    );

                uint32 LandId = tiles[aData.AccountCoordinate()].TileLandId();
                uint256 landamount = (amount * 5) / 100;
                address landAccount = getLandIdAccount(LandId);
                if (landAccount != address(0)) {
                    AccountsData[landAccount] += landamount << 128;
                } else {
                    LandIdMTs[LandId] += landamount;
                }

                emit LandHolderMTMinted(LandId, landamount);

                amount = (amount * 90) / 100;

                emit AccountMTMinted(account, amount);
                aData +=
                    (amount << 128) |
                    (AccountPerCollectionNFTMintedDiff << 80) |
                    (perMOPNPointMintedDiff << 32);
            } else {
                aData += (perMOPNPointMintedDiff << 32);
            }
        }
    }

    /**
     * @notice redeem account unclaimed minted mopn token
     * @param account account wallet address
     */
    function settleAndClaimAccountMT(
        address account
    ) public onlyMT returns (uint256 amount) {
        uint256 mData = settlePerMOPNPointMinted();
        address collectionAddress = getAccountCollection(account);
        uint256 cData = settleCollectionMT(collectionAddress, mData);
        uint256 aData = settleAccountMT(account, cData);
        amount = aData.AccountSettledMT();
        aData -= amount << 128;
        MiningData = mData;
        CollectionsData[collectionAddress] = cData;
        AccountsData[msg.sender] = aData;
    }

    /**
     * @notice get Land holder settled minted unclaimed mopn token
     * @param LandId MOPN Land Id
     */
    function getLandIdSettledMT(uint32 LandId) public view returns (uint256) {
        return uint48(LandIdMTs[LandId]);
    }

    function getLandIdAccount(uint32 LandId) public view returns (address) {
        return address(uint160(LandIdMTs[LandId] >> 48));
    }

    function registerLandAccount(address account) public {
        (
            address collectionAddress,
            uint256 mData,
            uint256 cData,
            uint256 aData
        ) = getPreProcessData(msg.sender);
        require(
            collectionAddress == governance.landContract(),
            "not a land account"
        );
        (, , uint256 tokenId) = IERC6551Account(payable(account)).token();
        AccountsData[account] += getLandIdSettledMT(uint32(tokenId)) << 128;
        LandIdMTs[uint32(tokenId)] = (uint256(uint160(account)) << 48);
    }

    function addMOPNPoint(
        address account,
        address collectionAddress,
        uint256 amount
    ) public onlyBomb {
        amount *= 100;
        uint256 mData = settlePerMOPNPointMinted();
        uint256 cData = settleCollectionMT(collectionAddress, mData);
        uint256 aData = settleAccountMT(account, cData);
        mData += amount << 48;
        cData += amount;
        MiningData = mData;
        CollectionsData[collectionAddress] = cData;
        AccountsData[account] = aData;
    }

    function subMOPNPoint(
        address account,
        address collectionAddress,
        uint256 amount
    ) public onlyBomb {
        amount *= 100;
        uint256 mData = settlePerMOPNPointMinted();
        uint256 cData = settleCollectionMT(collectionAddress, mData);
        uint256 aData = settleAccountMT(account, cData);
        mData -= amount << 48;
        cData -= amount;
        MiningData = mData;
        CollectionsData[collectionAddress] = cData;
        AccountsData[account] = aData;
    }

    function NFTOfferAccept(
        address collectionAddress,
        uint256 price
    )
        public
        onlyCollectionVault(collectionAddress)
        returns (uint256 oldNFTOfferCoefficient, uint256 newNFTOfferCoefficient)
    {
        uint256 meData = MiningDataExt;
        uint256 totalMTStakingRealtime = ((MiningData.MTTotalMinted() * 5) /
            100) -
            meData.TotalCollectionClaimed() +
            meData.TotalMTStaking();
        oldNFTOfferCoefficient = meData.NFTOfferCoefficient();
        newNFTOfferCoefficient =
            ((totalMTStakingRealtime + 1000000 - price) *
                oldNFTOfferCoefficient) /
            (totalMTStakingRealtime + 1000000);
        MiningDataExt =
            MiningDataExt -
            (oldNFTOfferCoefficient << 136) +
            (newNFTOfferCoefficient << 136);
    }

    function changeTotalMTStaking(
        address collectionAddress,
        uint256 direction,
        uint256 amount
    ) public onlyCollectionVault(collectionAddress) {
        if (direction > 0) {
            MiningDataExt += amount;
        } else {
            MiningDataExt -= amount;
        }
    }

    modifier onlyCollectionVault(address collectionAddress) {
        require(
            msg.sender == governance.getCollectionVault(collectionAddress),
            "only collection vault allowed"
        );
        _;
    }

    modifier onlyBomb() {
        require(msg.sender == governance.bombContract(), "only bomb allowed");
        _;
    }

    modifier onlyMOPNData() {
        require(
            msg.sender == governance.mopnDataContract(),
            "only mopn data allowed"
        );
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
