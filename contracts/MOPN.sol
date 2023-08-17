// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./erc6551/interfaces/IMOPNERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IMOPNCollectionVault.sol";
import "./libraries/TileMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
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
    using BitMaps for BitMaps.BitMap;

    uint256 public MTOutputPerSec;
    uint256 public MTStepStartTimestamp;

    uint256 public immutable MTReduceInterval;
    uint256 public immutable MaxCollectionOnMapNum;
    uint256 public immutable MaxCollectionMOPNPoint;

    // Tile => uint160 account + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    BitMaps.BitMap private tilesbitmap;

    /**
     * @notice Mining Data
     * @dev This includes the following data:
     * - uint48 TotalAdditionalMOPNPoints: bits 208-255
     * - uint64 TotalMOPNPoints: bits 144-207
     * - uint32 LastTickTimestamp: bits 112-143
     * - uint48 PerMOPNPointMinted: bits 64-111
     * - uint64 MTTotalMinted: bits 0-63
     */
    uint256 public MiningData;

    /// @notice MiningDataExt structure:
    /// - uint16 nextLandId: bits 176-191
    /// - uint48 AdditionalFinishSnapshot: bits 160-175
    /// - uint48 NFTOfferCoefficient: bits 112-159
    /// - uint48 TotalCollectionClaimed: bits 64-111
    /// - uint64 TotalMTStaking: bits 0-63
    uint256 public MiningDataExt;

    /// @notice CollectionData structure:
    /// - uint24 AdditionalMOPNPoint: bits 232-255
    /// - uint24 CollectionMOPNPoint: bits 208-231
    /// - uint32 OnMapMOPNPoints: bits 176-207
    /// - uint16 OnMapNftNumber: bits 160-175
    /// - uint48 PerCollectionNFTMinted: bits 112-159
    /// - uint48 PerMOPNPointMinted: bits 64-111
    /// - uint64 SettledMT: bits 0-63
    mapping(address => uint256) public CollectionsData;

    /// @notice AccountData structure:
    /// - uint32 Coordinate: bits 160-191
    /// - uint48 PerCollectionNFTMinted: bits 112-159
    /// - uint48 PerMOPNPointMinted: bits 64-111
    /// - uint64 SettledMT: bits 0-63
    mapping(address => uint256) public AccountsData;

    mapping(uint32 => address) public LandAccounts;

    IMOPNGovernance public governance;

    constructor(
        address governance_,
        uint256 MTOutputPerSec_,
        uint256 MTStepStartTimestamp_,
        uint256 MTReduceInterval_,
        uint256 MaxCollectionOnMapNum_,
        uint256 MaxCollectionMOPNPoint_
    ) {
        governance = IMOPNGovernance(governance_);
        MTOutputPerSec = MTOutputPerSec_;
        MTStepStartTimestamp = MTStepStartTimestamp_;
        MTReduceInterval = MTReduceInterval_;
        MaxCollectionOnMapNum = MaxCollectionOnMapNum_;
        MaxCollectionMOPNPoint = MaxCollectionMOPNPoint_;
        MiningData = MTStepStartTimestamp_ << 112;
        MiningDataExt = (10 ** 14) << 112;
    }

    function getGovernance() public view returns (address) {
        return address(governance);
    }

    function batchSetCollectionAdditionalMOPNPoints(
        address[] calldata collectionAddress,
        uint256[] calldata additionalMOPNPoints
    ) public onlyOwner {
        require(
            collectionAddress.length == additionalMOPNPoints.length,
            "params illegal"
        );
        for (uint256 i = 0; i < collectionAddress.length; i++) {
            CollectionsData[collectionAddress[i]] +=
                (additionalMOPNPoints[i] << 232) |
                (additionalMOPNPoints[i] << 208);
        }
    }

    function AdditionalMOPNPointFinish() public onlyOwner {
        require(AdditionalFinishSnapshot() == 0, "already finished");
        settlePerMOPNPointMinted();
        MiningDataExt += PerMOPNPointMinted() << 160;
        MiningData -= TotalAdditionalMOPNPoints() << 144;
    }

    function getQualifiedAccountCollection(
        address account
    ) public view returns (address, uint256) {
        (
            uint256 chainId,
            address collectionAddress,
            uint256 tokenId
        ) = IMOPNERC6551Account(payable(account)).token();

        if (AccountsData[account] == 0) {
            require(
                chainId == block.chainid,
                "not support cross chain account"
            );

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

        return (collectionAddress, tokenId);
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

    function get256bitmap(
        uint256 bitmap,
        uint256 index
    ) public pure returns (bool) {
        uint256 mask = 1 << (index & 0xff);
        return bitmap & mask != 0;
    }

    function set256bitmap(
        uint256 bitmap,
        uint256 index
    ) public pure returns (uint256) {
        uint256 mask = 1 << (index & 0xff);
        bitmap |= mask;
        return bitmap;
    }

    /**
     * @notice an on map NFT move to a new tile
     * @param tileCoordinate move To coordinate
     */
    function moveTo(uint32 tileCoordinate, uint32 LandId) public {
        require(block.timestamp > MTStepStartTimestamp, "mopn is not open yet");
        (address collectionAddress, ) = getQualifiedAccountCollection(
            msg.sender
        );

        require(!tilesbitmap.get(tileCoordinate), "dst Occupied");

        if (LandId == 0 || getTileLandId(tileCoordinate) != LandId) {
            require(
                TileMath.distance(
                    tileCoordinate,
                    TileMath.LandCenterTile(LandId)
                ) < 6,
                "LandId error"
            );
            if (LandId > NextLandId()) {
                uint256 nextLandId = IMOPNLand(governance.landContract())
                    .nextTokenId();
                require(nextLandId > LandId, "Land Not Open");
                MiningDataExt += (nextLandId - NextLandId()) << 176;
            }
        }

        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        settleAccountMT(msg.sender, collectionAddress);

        uint32 orgCoordinate = getAccountCoordinate(msg.sender);
        uint256 tileMOPNPoint = TileMath.getTileMOPNPoint(tileCoordinate);
        uint256 collectionOnMapNum = getCollectionOnMapNum(collectionAddress);
        if (orgCoordinate > 0) {
            tiles[orgCoordinate] = getTileLandId(orgCoordinate);
            tilesbitmap.unset(orgCoordinate);
            uint256 orgMOPNPoint = TileMath.getTileMOPNPoint(orgCoordinate);

            if (tileMOPNPoint > orgMOPNPoint) {
                tileMOPNPoint -= orgMOPNPoint;
            } else if (tileMOPNPoint < orgMOPNPoint) {
                tileMOPNPoint = orgMOPNPoint - tileMOPNPoint;
            }

            tileMOPNPoint *= 100;

            MiningData += tileMOPNPoint << 144;
            CollectionsData[collectionAddress] += tileMOPNPoint << 176;

            if (orgCoordinate > tileCoordinate) {
                AccountsData[msg.sender] -=
                    uint256(orgCoordinate - tileCoordinate) <<
                    160;
            } else {
                AccountsData[msg.sender] +=
                    uint256(tileCoordinate - orgCoordinate) <<
                    160;
            }

            emit AccountMove(msg.sender, LandId, orgCoordinate, tileCoordinate);
        } else {
            require(
                collectionOnMapNum < MaxCollectionOnMapNum,
                "collection on map nft number overflow"
            );

            tileMOPNPoint *= 100;

            uint256 collectinPoint = getCollectionMOPNPoint(collectionAddress);
            uint256 additionalMOPNPoint = getCollectionAdditionalMOPNPoint(
                collectionAddress
            );
            if (additionalMOPNPoint == 0) {
                MiningData += (tileMOPNPoint + collectinPoint) << 144;
            } else {
                MiningData +=
                    (additionalMOPNPoint << 208) |
                    ((tileMOPNPoint + collectinPoint + additionalMOPNPoint) <<
                        144);
            }

            CollectionsData[collectionAddress] +=
                (tileMOPNPoint << 176) |
                (uint256(1) << 160);

            AccountsData[msg.sender] += uint256(tileCoordinate) << 160;

            emit AccountJumpIn(msg.sender, LandId, tileCoordinate);
        }

        tiles[tileCoordinate] =
            (uint256(uint160(msg.sender)) << 32) |
            uint256(LandId);
        tilesbitmap.set(tileCoordinate);

        ++tileCoordinate;
        uint256 dstBitMap;
        for (uint256 i = 0; i < 18; i++) {
            if (
                !get256bitmap(dstBitMap, i) && tilesbitmap.get(tileCoordinate)
            ) {
                address tileAccount = getTileAccount(tileCoordinate);
                if (tileAccount != msg.sender) {
                    require(
                        getAccountCollection(tileAccount) == collectionAddress,
                        "tile has enemy"
                    );
                    dstBitMap = set256bitmap(dstBitMap, 100);
                }

                uint256 k = i;
                if (i < 5) {
                    k++;
                    while (k < 6) {
                        dstBitMap = set256bitmap(dstBitMap, k);
                        k++;
                    }
                    k = 6 + i * 2;

                    dstBitMap = set256bitmap(
                        dstBitMap,
                        (k - 3) < 6 ? 9 + k : k - 3
                    );

                    dstBitMap = set256bitmap(
                        dstBitMap,
                        (k - 2) < 6 ? 10 + k : k - 2
                    );
                    dstBitMap = set256bitmap(
                        dstBitMap,
                        (k - 1) < 6 ? 11 + k : k - 1
                    );
                    dstBitMap = set256bitmap(dstBitMap, k);
                    dstBitMap = set256bitmap(
                        dstBitMap,
                        (k + 1) > 17 ? (k - 11) : k + 1
                    );
                    dstBitMap = set256bitmap(
                        dstBitMap,
                        (k + 2) > 17 ? (k - 10) : k + 2
                    );
                    dstBitMap = set256bitmap(
                        dstBitMap,
                        (k + 3) > 17 ? (k - 9) : k + 3
                    );
                } else {
                    if (k < 16) {
                        dstBitMap = set256bitmap(dstBitMap, k + 1);
                        dstBitMap = set256bitmap(dstBitMap, k + 2);
                    } else if (k == 16) {
                        dstBitMap = set256bitmap(dstBitMap, 17);
                    }
                }
            }

            if (i == 5) {
                tileCoordinate += 10001;
            } else if (i < 5) {
                tileCoordinate = neighbor(tileCoordinate, i);
            } else {
                tileCoordinate = neighbor(tileCoordinate, (i - 6) / 2);
            }
        }

        if (!get256bitmap(dstBitMap, 100)) {
            require(
                collectionOnMapNum == 0 ||
                    (orgCoordinate > 0 && collectionOnMapNum == 1),
                "linked avatar missing"
            );
        }
    }

    /**
     * @notice throw a bomb to a tile
     * @param tileCoordinate bomb to tile coordinate
     */
    function bomb(uint32 tileCoordinate, uint256 num) public {
        getQualifiedAccountCollection(msg.sender);

        require(getAccountCoordinate(msg.sender) > 0, "NFT not on the map");

        address[] memory attackAccounts = new address[](7);
        uint32[] memory victimsCoordinates = new uint32[](7);

        uint256 killed;
        address victimsCollection;
        uint256 collectinPoint;
        uint256 additionalMOPNPoint;

        uint256 cData;
        settlePerMOPNPointMinted();
        uint256 mData = MiningData;
        for (uint256 i = 0; i < 7; i++) {
            if (tilesbitmap.get(tileCoordinate)) {
                address attackAccount = getTileAccount(tileCoordinate);
                if (attackAccount != msg.sender) {
                    uint256 shield = IMOPNBomb(governance.bombContract())
                        .balanceOf(attackAccount, 2);
                    if (shield < num) {
                        //remove tile account
                        tiles[tileCoordinate] = getTileLandId(tileCoordinate);
                        tilesbitmap.unset(tileCoordinate);

                        attackAccounts[i] = attackAccount;
                        victimsCoordinates[i] = tileCoordinate;
                        if (victimsCollection == address(0)) {
                            victimsCollection = getAccountCollection(
                                attackAccount
                            );
                            settleCollectionMT(victimsCollection);
                            collectinPoint = getCollectionMOPNPoint(
                                victimsCollection
                            );
                            additionalMOPNPoint = getCollectionAdditionalMOPNPoint(
                                victimsCollection
                            );
                            cData = CollectionsData[victimsCollection];
                        }

                        settleAccountMT(attackAccount, victimsCollection);

                        uint256 accountOnMapMOPNPoint = TileMath
                            .getTileMOPNPoint(tileCoordinate) * 100;
                        if (additionalMOPNPoint == 0) {
                            mData -=
                                (accountOnMapMOPNPoint + collectinPoint) <<
                                144;
                        } else {
                            mData -=
                                (additionalMOPNPoint << 208) |
                                ((accountOnMapMOPNPoint + collectinPoint) <<
                                    144);
                        }

                        cData -=
                            (accountOnMapMOPNPoint << 176) |
                            (uint256(1) << 160);

                        AccountsData[attackAccount] -=
                            uint256(tileCoordinate) <<
                            160;
                        killed++;

                        if (shield > 0) {
                            governance.burnBomb(msg.sender, 2, shield, 0);
                        }
                    } else {
                        governance.burnBomb(msg.sender, 2, num, 0);
                    }
                }
            }

            if (i == 0) {
                ++tileCoordinate;
            } else {
                tileCoordinate = neighbor(tileCoordinate, i - 1);
            }
        }

        governance.burnBomb(msg.sender, 1, num, killed > 0 ? 1 : 0);

        MiningData = mData;
        CollectionsData[victimsCollection] = cData;

        --tileCoordinate;
        emit BombUse(
            msg.sender,
            tileCoordinate,
            attackAccounts,
            victimsCoordinates
        );
    }

    /**
     * @notice get the avatar Id who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileAccount(
        uint32 tileCoordinate
    ) public view returns (address) {
        return address(uint160(tiles[tileCoordinate] >> 32));
    }

    /**
     * @notice get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)
     * @param tileCoordinate tile coordinate
     */
    function getTileLandId(uint32 tileCoordinate) public view returns (uint32) {
        return uint32(tiles[tileCoordinate]);
    }

    // MiningData
    function TotalAdditionalMOPNPoints() public view returns (uint256) {
        return uint48(MiningData >> 208);
    }

    function TotalMOPNPoints() public view returns (uint256) {
        return uint64(MiningData >> 144);
    }

    function LastTickTimestamp() public view returns (uint256) {
        return uint32(MiningData >> 112);
    }

    function PerMOPNPointMinted() public view returns (uint256) {
        return uint48(MiningData >> 64);
    }

    function MTTotalMinted() public view returns (uint256) {
        return uint64(MiningData);
    }

    // MiningDataExt
    function NextLandId() public view returns (uint256) {
        return uint16(MiningDataExt >> 176);
    }

    function AdditionalFinishSnapshot() public view returns (uint256) {
        return uint48(MiningDataExt >> 160);
    }

    function NFTOfferCoefficient() public view returns (uint256) {
        return uint48(MiningDataExt >> 112);
    }

    function TotalCollectionClaimed() public view returns (uint256) {
        return uint48(MiningDataExt >> 64);
    }

    function TotalMTStaking() public view returns (uint256) {
        return uint64(MiningDataExt);
    }

    /// CollectionData
    function getCollectionAdditionalMOPNPoint(
        address collectionAddress
    ) public view returns (uint256) {
        return uint24(CollectionsData[collectionAddress] >> 232);
    }

    function getCollectionAdditionalMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            uint24(CollectionsData[collectionAddress] >> 232) *
            getCollectionOnMapNum(collectionAddress);
    }

    function getCollectionMOPNPoint(
        address collectionAddress
    ) public view returns (uint256) {
        return uint24(CollectionsData[collectionAddress] >> 208);
    }

    function getCollectionMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            uint24(CollectionsData[collectionAddress] >> 208) *
            getCollectionOnMapNum(collectionAddress);
    }

    function getCollectionOnMapMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return uint32(CollectionsData[collectionAddress] >> 176);
    }

    function getCollectionOnMapNum(
        address collectionAddress
    ) public view returns (uint256) {
        return uint16(CollectionsData[collectionAddress] >> 160);
    }

    function getPerCollectionNFTMinted(
        address collectionAddress
    ) public view returns (uint256) {
        return uint48(CollectionsData[collectionAddress] >> 112);
    }

    function getCollectionPerMOPNPointMinted(
        address collectionAddress
    ) public view returns (uint256) {
        return uint48(CollectionsData[collectionAddress] >> 64);
    }

    function getCollectionSettledMT(
        address collectionAddress
    ) public view returns (uint256) {
        return uint64(CollectionsData[collectionAddress]);
    }

    /// AccountData
    function getAccountCoordinate(
        address account
    ) public view returns (uint32) {
        return uint32(AccountsData[account] >> 160);
    }

    function getAccountPerCollectionNFTMinted(
        address account
    ) public view returns (uint256) {
        return uint48(AccountsData[account] >> 112);
    }

    /**
     * @notice get avatar settled per mopn token allocation weight minted mopn token number
     * @param account account wallet address
     */
    function getAccountPerMOPNPointMinted(
        address account
    ) public view returns (uint256) {
        return uint48(AccountsData[account] >> 64);
    }

    /**
     * @notice get avatar settled unclaimed minted mopn token
     * @param account account wallet address
     */
    function getAccountSettledMT(
        address account
    ) public view returns (uint256) {
        return uint64(AccountsData[account]);
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
    function settlePerMOPNPointMinted() public {
        uint256 lastTickTimestamp = LastTickTimestamp();
        if (block.timestamp > lastTickTimestamp) {
            uint256 reduceTimes = MTReduceTimes();
            uint256 totalMOPNPoints = TotalMOPNPoints();
            if (totalMOPNPoints > 0) {
                uint256 PerMOPNPointMintDiff;
                if (reduceTimes == 0) {
                    PerMOPNPointMintDiff +=
                        ((block.timestamp - lastTickTimestamp) *
                            MTOutputPerSec) /
                        totalMOPNPoints;
                } else {
                    uint256 nextReduceTimestamp = MTStepStartTimestamp +
                        MTReduceInterval;
                    for (uint256 i = 0; i <= reduceTimes; i++) {
                        PerMOPNPointMintDiff +=
                            ((nextReduceTimestamp - lastTickTimestamp) *
                                currentMTPPS(i)) /
                            totalMOPNPoints;
                        lastTickTimestamp = nextReduceTimestamp;
                        nextReduceTimestamp += MTReduceInterval;
                        if (nextReduceTimestamp > block.timestamp) {
                            nextReduceTimestamp = block.timestamp;
                        }
                    }
                }

                MiningData +=
                    ((block.timestamp - LastTickTimestamp()) << 112) |
                    ((PerMOPNPointMintDiff) << 64) |
                    (PerMOPNPointMintDiff * totalMOPNPoints);
            } else {
                MiningData += (block.timestamp - lastTickTimestamp) << 112;
            }

            if (reduceTimes > 0) {
                MTOutputPerSec = currentMTPPS(reduceTimes);
                MTStepStartTimestamp += reduceTimes * MTReduceInterval;
            }
        }
    }

    function getCollectionMOPNPointFromStaking(
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
    function settleCollectionMT(address collectionAddress) public {
        uint256 perMOPNPointMinted = PerMOPNPointMinted();
        uint256 collectionPerMOPNPointMinted = getCollectionPerMOPNPointMinted(
            collectionAddress
        );
        uint256 collectionPerMOPNPointMintedDiff = perMOPNPointMinted -
            collectionPerMOPNPointMinted;
        if (collectionPerMOPNPointMintedDiff > 0) {
            uint256 additionalFinishSnapshot_ = AdditionalFinishSnapshot();
            if (additionalFinishSnapshot_ > collectionPerMOPNPointMinted) {
                collectionPerMOPNPointMintedDiff =
                    additionalFinishSnapshot_ -
                    collectionPerMOPNPointMinted;
            }
            uint256 OnMapMOPNPoints = getCollectionOnMapMOPNPoints(
                collectionAddress
            );
            if (OnMapMOPNPoints > 0) {
                uint256 CollectionMOPNPoints = getCollectionMOPNPoints(
                    collectionAddress
                );

                uint256 amount = ((collectionPerMOPNPointMintedDiff *
                    (OnMapMOPNPoints + CollectionMOPNPoints)) * 5) / 100;

                if (CollectionMOPNPoints > 0) {
                    CollectionsData[collectionAddress] +=
                        (((collectionPerMOPNPointMintedDiff *
                            CollectionMOPNPoints) /
                            getCollectionOnMapNum(collectionAddress)) << 112) |
                        (collectionPerMOPNPointMintedDiff << 64) |
                        amount;
                } else {
                    CollectionsData[collectionAddress] +=
                        (collectionPerMOPNPointMintedDiff << 64) |
                        amount;
                }

                emit CollectionMTMinted(collectionAddress, amount);
            } else {
                CollectionsData[collectionAddress] +=
                    collectionPerMOPNPointMintedDiff <<
                    64;
            }

            if (additionalFinishSnapshot_ > collectionPerMOPNPointMinted) {
                uint256 additionalMOPNPoint = getCollectionAdditionalMOPNPoint(
                    collectionAddress
                );
                CollectionsData[collectionAddress] -=
                    (additionalMOPNPoint << 232) |
                    (additionalMOPNPoint << 208);
                settleCollectionMT(collectionAddress);
            }
        }
    }

    function claimCollectionMT(
        address collectionAddress
    ) public returns (uint256 amount) {
        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        amount = getCollectionSettledMT(collectionAddress);
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
            CollectionsData[collectionAddress] -= amount;
            MiningDataExt += (amount << 64) | amount;
        }
    }

    function settleCollectionMOPNPoint(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) {
        uint256 point = getCollectionMOPNPointFromStaking(collectionAddress) +
            getCollectionAdditionalMOPNPoint(collectionAddress);
        uint256 lastPoint = uint24(CollectionsData[collectionAddress] >> 208);
        if (point != lastPoint) {
            uint256 collectionMOPNPoints = point *
                getCollectionOnMapNum(collectionAddress);

            uint256 preCollectionMOPNPoints = lastPoint *
                getCollectionOnMapNum(collectionAddress);

            if (collectionMOPNPoints > preCollectionMOPNPoints) {
                MiningData += collectionMOPNPoints - preCollectionMOPNPoints;
            } else if (collectionMOPNPoints < preCollectionMOPNPoints) {
                MiningData -= preCollectionMOPNPoints - collectionMOPNPoints;
            }

            CollectionsData[collectionAddress] =
                CollectionsData[collectionAddress] -
                (lastPoint << 208) +
                (point << 208);
        }
    }

    function accountClaimAvailable(address account) public view returns (bool) {
        return
            getAccountSettledMT(account) > 0 ||
            getAccountCoordinate(account) > 0;
    }

    function getAccountCollection(
        address account
    ) public view returns (address collectionAddress) {
        (, collectionAddress, ) = IMOPNERC6551Account(payable(account)).token();
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param account account wallet address
     */
    function getAccountOnMapMOPNPoint(
        address account
    ) public view returns (uint256 OnMapMOPNPoint) {
        uint32 coordinate = getAccountCoordinate(account);
        if (coordinate > 0) {
            OnMapMOPNPoint = TileMath.getTileMOPNPoint(coordinate) * 100;
        }
    }

    /**
     * @notice mint avatar mopn token
     * @param account account wallet address
     */
    function settleAccountMT(
        address account,
        address collectionAddress
    ) public {
        uint256 AccountPerMOPNPointMintedDiff = PerMOPNPointMinted() -
            getAccountPerMOPNPointMinted(account);
        if (AccountPerMOPNPointMintedDiff > 0) {
            uint32 coordinate = getAccountCoordinate(account);
            if (coordinate > 0) {
                uint256 AccountOnMapMOPNPoint = TileMath.getTileMOPNPoint(
                    coordinate
                ) * 100;
                uint256 AccountPerCollectionNFTMintedDiff = getPerCollectionNFTMinted(
                        collectionAddress
                    ) - getAccountPerCollectionNFTMinted(account);

                uint256 amount = AccountPerMOPNPointMintedDiff *
                    AccountOnMapMOPNPoint +
                    (
                        AccountPerCollectionNFTMintedDiff > 0
                            ? AccountPerCollectionNFTMintedDiff
                            : 0
                    );

                uint32 LandId = getTileLandId(coordinate);
                address landAccount = LandAccounts[LandId];
                if (landAccount == address(0)) {
                    landAccount = getLandAccount(LandId);
                    LandAccounts[LandId] = landAccount;
                }
                uint256 landamount = (amount * 5) / 100;
                AccountsData[landAccount] += landamount;

                emit LandHolderMTMinted(LandId, landamount);

                amount = (amount * 90) / 100;

                emit AccountMTMinted(account, amount);
                AccountsData[account] +=
                    (AccountPerCollectionNFTMintedDiff << 112) |
                    (AccountPerMOPNPointMintedDiff << 64) |
                    amount;
            } else {
                AccountsData[account] += AccountPerMOPNPointMintedDiff << 64;
            }
        }
    }

    function batchsettleAccountMT(address[][] memory accounts) public {
        settlePerMOPNPointMinted();
        address collectionAddress;
        for (uint256 i = 0; i < accounts.length; i++) {
            collectionAddress = address(0);
            for (uint256 k = 0; k < accounts[i].length; k++) {
                if (
                    !IMOPNERC6551Account(payable(accounts[i][k])).isOwner(
                        msg.sender
                    )
                ) {
                    continue;
                }

                if (collectionAddress == address(0)) {
                    collectionAddress = getAccountCollection(accounts[i][k]);
                    settleCollectionMT(collectionAddress);
                }

                settleAccountMT(accounts[i][k], collectionAddress);
            }
        }
    }

    function batchClaimAccountMT(address[][] memory accounts) public {
        settlePerMOPNPointMinted();
        uint256 amount;
        address collectionAddress;
        for (uint256 i = 0; i < accounts.length; i++) {
            collectionAddress = address(0);
            for (uint256 k = 0; k < accounts[i].length; k++) {
                if (
                    !IMOPNERC6551Account(payable(accounts[i][k])).isOwner(
                        msg.sender
                    )
                ) {
                    continue;
                }

                if (collectionAddress == address(0)) {
                    collectionAddress = getAccountCollection(accounts[i][k]);
                    settleCollectionMT(collectionAddress);
                }

                settleAccountMT(accounts[i][k], collectionAddress);
                amount += _claimAccountMT(accounts[i][k]);
            }
        }
        governance.mintMT(msg.sender, amount);
    }

    function claimAccountMT(address account) public onlyMT returns (uint256) {
        settlePerMOPNPointMinted();
        address collectionAddress = getAccountCollection(account);
        settleCollectionMT(collectionAddress);
        settleAccountMT(account, collectionAddress);
        return _claimAccountMT(account);
    }

    function _claimAccountMT(
        address account
    ) internal returns (uint256 amount) {
        amount = getAccountSettledMT(account);
        if (amount > 0) {
            AccountsData[account] -= amount;
        }
    }

    function getLandAccount(uint256 LandId) public view returns (address) {
        return
            IERC6551Registry(governance.ERC6551Registry()).account(
                governance.ERC6551AccountProxy(),
                block.chainid,
                governance.landContract(),
                LandId,
                0
            );
    }

    function NFTOfferAccept(
        address collectionAddress,
        uint256 price
    )
        public
        onlyCollectionVault(collectionAddress)
        returns (uint256 oldNFTOfferCoefficient, uint256 newNFTOfferCoefficient)
    {
        uint256 totalMTStakingRealtime = ((MTTotalMinted() * 5) / 100) -
            TotalCollectionClaimed() +
            TotalMTStaking();
        oldNFTOfferCoefficient = NFTOfferCoefficient();
        newNFTOfferCoefficient =
            ((totalMTStakingRealtime + 1000000 - price) *
                oldNFTOfferCoefficient) /
            (totalMTStakingRealtime + 1000000);
        MiningDataExt =
            MiningDataExt -
            (oldNFTOfferCoefficient << 112) +
            (newNFTOfferCoefficient << 112);
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
