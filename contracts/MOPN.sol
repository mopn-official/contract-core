// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./erc6551/interfaces/IERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IMOPNCollectionVault.sol";
import "./libraries/TileMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
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
    uint256 public MTOutputPerSec;
    uint256 public MTStepStartTimestamp;

    uint256 public immutable MTReduceInterval;
    uint256 public immutable MaxCollectionOnMapNum;
    uint256 public immutable MaxCollectionMOPNPoint;

    // Tile => uint160 account + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    /// @notice uint96 MTTotalMinted + uint32 LastTickTimestamp + uint64 PerMOPNPointMinted + uint64 TotalMOPNPoints
    uint256 public MiningData;

    /// @notice uint32 AdditionalFinishSnapshot + uint32 TotalAdditionalMOPNPoints + uint64 NFTOfferCoefficient + uint64 TotalCollectionClaimed + uint64 TotalMTStaking
    uint256 public MiningDataExt;

    struct AccountData {
        uint256 SettledMT;
        uint256 PerCollectionNFTMinted;
        uint256 PerMOPNPointMinted;
        uint32 coordinate;
    }

    /// @notice  uint64 settled MT + uint48 PerCollectionNFTMinted  + uint48 PerMOPNPointMinted + uint32 coordinate
    mapping(address => uint256) public AccountsData;

    struct CollectionData {
        uint256 SettledMT;
        uint256 PerCollectionNFTMinted;
        uint256 PerMOPNPointMinted;
        uint256 CollectionMOPNPoint;
        uint256 AdditionalMOPNPoint;
        uint256 OnMapNftNumber;
        uint256 OnMapMOPNPoints;
        uint256 CollectionMOPNPoints;
        uint256 AdditionalMOPNPoints;
    }

    /// @notice uint64 mintedMT + uint48 PerCollectionNFTMinted + uint48 PerMOPNPointMinted + uint24 CollectionMOPNPoint
    ///         + uint24 AdditionalMOPNPoint + uint16 OnMapNftNumber + uint32 OnMapMOPNPoints
    mapping(address => uint256) public CollectionsData;

    /// @notice uint160 account address +  uint96 settled MT
    mapping(uint32 => uint256) public LandIdMTs;

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
        MiningData = MTStepStartTimestamp_ << 128;
        MiningDataExt = (10 ** 17) << 128;
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
                additionalMOPNPoints[i] <<
                48;
        }
    }

    function AdditionalMOPNPointFinish() public onlyOwner {
        require(AdditionalFinishSnapshot() == 0, "already finished");
        settlePerMOPNPointMinted();
        MiningDataExt += PerMOPNPointMinted() << 224;
        MiningData -= TotalAdditionalMOPNPoints();
    }

    function getQualifiedAccountCollection(
        address account
    ) public view returns (address, uint256) {
        require(
            IERC165(payable(account)).supportsInterface(
                type(IERC6551Account).interfaceId
            ),
            "not erc6551 account"
        );

        (
            uint256 chainId,
            address collectionAddress,
            uint256 tokenId
        ) = IERC6551Account(payable(account)).token();

        require(chainId == block.chainid, "not support cross chain account");

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

    /**
     * @notice an on map avatar move to a new tile
     * @param tileCoordinate NFT move To coordinate
     */
    function moveTo(uint32 tileCoordinate, uint32 LandId) public {
        require(block.timestamp > MTStepStartTimestamp, "mopn is not open yet");
        (address collectionAddress, ) = getQualifiedAccountCollection(
            msg.sender
        );

        require(getTileAccount(tileCoordinate) == address(0), "dst Occupied");

        if (LandId == 0 || getTileLandId(tileCoordinate) != LandId) {
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

        uint32 orgCoordinate = getAccountCoordinate(msg.sender);
        uint256 orgMOPNPoint;
        uint256 tileMOPNPoint = TileMath.getTileMOPNPoint(tileCoordinate);
        if (orgCoordinate > 0) {
            tiles[orgCoordinate] = getTileLandId(orgCoordinate);
            orgMOPNPoint = TileMath.getTileMOPNPoint(orgCoordinate);

            emit AccountMove(msg.sender, LandId, orgCoordinate, tileCoordinate);
        } else {
            require(
                getCollectionOnMapNum(collectionAddress) <
                    MaxCollectionOnMapNum,
                "collection on map nft number overflow"
            );
            tileMOPNPoint += IMOPNBomb(governance.bombContract()).balanceOf(
                msg.sender,
                2
            );
            emit AccountJumpIn(msg.sender, LandId, tileCoordinate);
        }

        bool collectionLinked;
        ++tileCoordinate;
        for (uint256 i = 0; i < 18; i++) {
            address tileAccount = getTileAccount(tileCoordinate);
            if (tileAccount != address(0) && tileAccount != msg.sender) {
                address tileCollectionAddress = getAccountCollection(
                    tileAccount
                );
                require(
                    tileCollectionAddress == collectionAddress,
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

        if (collectionLinked == false) {
            uint256 collectionOnMapNum = getCollectionOnMapNum(
                collectionAddress
            );
            require(
                collectionOnMapNum == 0 ||
                    (orgCoordinate > 0 && collectionOnMapNum == 1),
                "linked avatar missing"
            );
        }

        tileCoordinate -= 2;
        tiles[tileCoordinate] =
            (uint256(uint160(msg.sender)) << 32) |
            uint256(LandId);
        if (tileMOPNPoint > orgMOPNPoint) {
            _addMOPNPoint(
                msg.sender,
                collectionAddress,
                tileMOPNPoint - orgMOPNPoint
            );
        } else if (tileMOPNPoint < orgMOPNPoint) {
            _subMOPNPoint(
                msg.sender,
                collectionAddress,
                orgMOPNPoint - tileMOPNPoint
            );
        }
        AccountsData[msg.sender] =
            AccountsData[msg.sender] -
            orgCoordinate +
            tileCoordinate;
    }

    /**
     * @notice throw a bomb to a tile
     * @param tileCoordinate bomb to tile coordinate
     */
    function bomb(uint32 tileCoordinate) public {
        getQualifiedAccountCollection(msg.sender);

        require(getAccountCoordinate(msg.sender) > 0, "NFT not on the map");

        address[] memory attackAccounts = new address[](7);
        uint32[] memory victimsCoordinates = new uint32[](7);
        uint32 orgTileCoordinate = tileCoordinate;

        uint256 killed;
        for (uint256 i = 0; i < 7; i++) {
            address attackAccount = getTileAccount(tileCoordinate);
            if (attackAccount != address(0) && attackAccount != msg.sender) {
                //remove tile account
                tiles[tileCoordinate] = getTileLandId(tileCoordinate);
                //remove account tile
                attackAccounts[i] = attackAccount;
                victimsCoordinates[i] = tileCoordinate;
                _subMOPNPoint(
                    attackAccount,
                    getAccountCollection(attackAccount),
                    0
                );
                AccountsData[attackAccount] -= tileCoordinate;
                killed++;
            }

            if (i == 0) {
                ++tileCoordinate;
            } else {
                tileCoordinate = neighbor(tileCoordinate, i - 1);
            }
        }

        governance.burnBomb(msg.sender, 1, killed);

        emit BombUse(
            msg.sender,
            orgTileCoordinate,
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

    function MTTotalMinted() public view returns (uint256) {
        return uint96(MiningData >> 160);
    }

    /**
     * @notice get last per mopn token allocation weight minted settlement timestamp
     */
    function LastTickTimestamp() public view returns (uint256) {
        return uint32(MiningData >> 128);
    }

    /**
     * @notice get settled Per MT Allocation Weight minted mopn token number
     */
    function PerMOPNPointMinted() public view returns (uint256) {
        return uint64(MiningData >> 64);
    }

    /**
     * @notice get total mopn token allocation weights
     */
    function TotalMOPNPoints() public view returns (uint256) {
        return uint64(MiningData);
    }

    function AdditionalFinishSnapshot() public view returns (uint256) {
        return uint32(MiningDataExt >> 224);
    }

    function TotalAdditionalMOPNPoints() public view returns (uint256) {
        return uint32(MiningDataExt >> 192);
    }

    function NFTOfferCoefficient() public view returns (uint256) {
        return uint64(MiningDataExt >> 128);
    }

    function TotalCollectionClaimed() public view returns (uint256) {
        return uint64(MiningDataExt >> 64);
    }

    function TotalMTStaking() public view returns (uint256) {
        return uint64(MiningDataExt);
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
                uint256 perMOPNPointMinted = PerMOPNPointMinted();
                if (reduceTimes == 0) {
                    perMOPNPointMinted +=
                        ((block.timestamp - lastTickTimestamp) *
                            MTOutputPerSec) /
                        totalMOPNPoints;
                } else {
                    uint256 nextReduceTimestamp = MTStepStartTimestamp +
                        MTReduceInterval;
                    for (uint256 i = 0; i <= reduceTimes; i++) {
                        perMOPNPointMinted +=
                            ((nextReduceTimestamp - lastTickTimestamp) *
                                currentMTPPS(i)) /
                            totalMOPNPoints;
                        lastTickTimestamp = nextReduceTimestamp;
                        nextReduceTimestamp += MTReduceInterval;
                    }
                }

                uint256 PerMOPNPointMintDiff = perMOPNPointMinted -
                    PerMOPNPointMinted();
                MiningData +=
                    ((PerMOPNPointMintDiff * totalMOPNPoints) << 160) |
                    ((block.timestamp - LastTickTimestamp()) << 128) |
                    ((PerMOPNPointMintDiff) << 64);
            } else {
                MiningData += (block.timestamp - lastTickTimestamp) << 128;
            }

            if (reduceTimes > 0) {
                MTOutputPerSec = currentMTPPS(reduceTimes);
                MTStepStartTimestamp += reduceTimes * MTReduceInterval;
            }
        }
    }

    function calcPerMOPNPointMinted() public view returns (uint256) {
        if (MTStepStartTimestamp > block.timestamp) {
            return 0;
        }
        uint256 totalMOPNPoints = TotalMOPNPoints();
        uint256 perMOPNPointMinted = PerMOPNPointMinted();
        if (totalMOPNPoints > 0) {
            uint256 lastTickTimestamp = LastTickTimestamp();
            uint256 reduceTimes = MTReduceTimes();
            if (reduceTimes == 0) {
                perMOPNPointMinted +=
                    ((block.timestamp - lastTickTimestamp) *
                        currentMTPPS(reduceTimes)) /
                    totalMOPNPoints;
            } else {
                uint256 nextReduceTimestamp = MTStepStartTimestamp +
                    MTReduceInterval;
                for (uint256 i = 0; i <= reduceTimes; i++) {
                    perMOPNPointMinted +=
                        ((nextReduceTimestamp - lastTickTimestamp) *
                            currentMTPPS(i)) /
                        totalMOPNPoints;
                    lastTickTimestamp = nextReduceTimestamp;
                    nextReduceTimestamp += MTReduceInterval;
                }
            }
        }
        return perMOPNPointMinted;
    }

    function getCollectionSettledMT(
        address collectionAddress
    ) public view returns (uint256) {
        return uint64(CollectionsData[collectionAddress] >> 192);
    }

    function getPerCollectionNFTMinted(
        address collectionAddress
    ) public view returns (uint256) {
        return uint48(CollectionsData[collectionAddress] >> 144);
    }

    function getCollectionPerMOPNPointMinted(
        address collectionAddress
    ) public view returns (uint256) {
        return uint48(CollectionsData[collectionAddress] >> 96);
    }

    function getCollectionMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            uint24(CollectionsData[collectionAddress] >> 72) *
            getCollectionOnMapNum(collectionAddress);
    }

    function getCollectionAdditionalMOPNPoint(
        address collectionAddress
    ) public view returns (uint256) {
        return uint24(CollectionsData[collectionAddress] >> 48);
    }

    function getCollectionAdditionalMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            uint24(CollectionsData[collectionAddress] >> 48) *
            getCollectionOnMapNum(collectionAddress);
    }

    /**
     * @notice get NFT collection On map avatar number
     * @param collectionAddress collection contract address
     */
    function getCollectionOnMapNum(
        address collectionAddress
    ) public view returns (uint256) {
        return uint16(CollectionsData[collectionAddress] >> 32);
    }

    function getCollectionOnMapMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return uint32(CollectionsData[collectionAddress]);
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

    function _unpackedCollectionData(
        uint256 packed
    ) private pure returns (CollectionData memory collectionData) {
        collectionData.SettledMT = uint64(packed >> 192);
        collectionData.PerCollectionNFTMinted = uint48(packed >> 144);
        collectionData.PerMOPNPointMinted = uint48(packed >> 96);
        collectionData.CollectionMOPNPoint = uint24(packed >> 72);
        collectionData.AdditionalMOPNPoint = uint24(packed >> 48);
        collectionData.OnMapNftNumber = uint16(packed >> 32);
        collectionData.OnMapMOPNPoints = uint32(packed);
        collectionData.CollectionMOPNPoints =
            collectionData.CollectionMOPNPoint *
            collectionData.OnMapNftNumber;
        collectionData.AdditionalMOPNPoints =
            collectionData.AdditionalMOPNPoint *
            collectionData.OnMapNftNumber;
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param collectionAddress collection contract address
     */
    function calcCollectionSettledMT(
        address collectionAddress
    ) public view returns (uint256 inbox) {
        inbox = getCollectionSettledMT(collectionAddress);
        uint256 perMOPNPointMinted = calcPerMOPNPointMinted();
        uint256 CollectionPerMOPNPointMinted = getCollectionPerMOPNPointMinted(
            collectionAddress
        );
        uint256 AdditionalMOPNPoints = getCollectionAdditionalMOPNPoints(
            collectionAddress
        );
        uint256 CollectionMOPNPoints = getCollectionMOPNPoints(
            collectionAddress
        );
        uint256 OnMapMOPNPoints = getCollectionOnMapMOPNPoints(
            collectionAddress
        );

        if (
            CollectionPerMOPNPointMinted < perMOPNPointMinted &&
            OnMapMOPNPoints > 0
        ) {
            inbox +=
                (((perMOPNPointMinted - CollectionPerMOPNPointMinted) *
                    (CollectionMOPNPoints + OnMapMOPNPoints)) * 5) /
                100;
            if (AdditionalMOPNPoints > 0) {
                if (AdditionalFinishSnapshot() > 0) {
                    inbox +=
                        (((AdditionalFinishSnapshot() -
                            CollectionPerMOPNPointMinted) *
                            AdditionalMOPNPoints) * 5) /
                        100;
                } else {
                    inbox +=
                        (((perMOPNPointMinted - CollectionPerMOPNPointMinted) *
                            AdditionalMOPNPoints) * 5) /
                        100;
                }
            }
        }
    }

    function calcPerCollectionNFTMintedMT(
        address collectionAddress
    ) public view returns (uint256 result) {
        result = getPerCollectionNFTMinted(collectionAddress);

        uint256 CollectionPerMOPNPointMinted = getCollectionPerMOPNPointMinted(
            collectionAddress
        );
        uint256 CollectionPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
            CollectionPerMOPNPointMinted;
        if (
            CollectionPerMOPNPointMintedDiff > 0 &&
            getCollectionOnMapMOPNPoints(collectionAddress) > 0
        ) {
            uint256 CollectionMOPNPoints = getCollectionMOPNPoints(
                collectionAddress
            );

            if (CollectionMOPNPoints > 0) {
                result += ((CollectionPerMOPNPointMintedDiff *
                    CollectionMOPNPoints) /
                    getCollectionOnMapNum(collectionAddress));
            }

            uint256 AdditionalMOPNPoints = getCollectionAdditionalMOPNPoints(
                collectionAddress
            );
            if (AdditionalMOPNPoints > 0) {
                uint256 AdditionalFinishSnapshot_ = AdditionalFinishSnapshot();
                if (AdditionalFinishSnapshot_ > 0) {
                    if (
                        AdditionalFinishSnapshot_ > CollectionPerMOPNPointMinted
                    ) {
                        result += (((AdditionalFinishSnapshot_ -
                            CollectionPerMOPNPointMinted) *
                            AdditionalMOPNPoints) /
                            getCollectionOnMapNum(collectionAddress));
                    }
                } else {
                    result += (((CollectionPerMOPNPointMintedDiff) *
                        AdditionalMOPNPoints) /
                        getCollectionOnMapNum(collectionAddress));
                }
            }
        }
    }

    /**
     * @notice mint collection mopn token
     * @param collectionAddress collection contract address
     */
    function settleCollectionMT(address collectionAddress) public {
        uint256 unpacked = CollectionsData[collectionAddress];
        uint256 perMOPNPointMinted = uint48(unpacked >> 96);
        uint256 perMOPNPointMintedDiff = PerMOPNPointMinted() -
            perMOPNPointMinted;
        if (perMOPNPointMintedDiff > 0) {
            CollectionData memory cData = _unpackedCollectionData(unpacked);
            unpacked += perMOPNPointMintedDiff << 96;
            if (cData.OnMapMOPNPoints > 0) {
                uint256 amount = ((perMOPNPointMintedDiff *
                    (cData.OnMapMOPNPoints + cData.CollectionMOPNPoints)) * 5) /
                    100;

                if (cData.CollectionMOPNPoints > 0) {
                    unpacked +=
                        ((perMOPNPointMintedDiff * cData.CollectionMOPNPoints) /
                            cData.OnMapNftNumber) <<
                        144;
                }

                if (cData.AdditionalMOPNPoints > 0) {
                    uint256 AdditionalFinishSnapshot_ = AdditionalFinishSnapshot();
                    if (AdditionalFinishSnapshot_ > 0) {
                        if (AdditionalFinishSnapshot_ > perMOPNPointMinted) {
                            amount +=
                                (((AdditionalFinishSnapshot_ -
                                    perMOPNPointMinted) *
                                    cData.AdditionalMOPNPoints) * 5) /
                                100;
                            unpacked +=
                                (((AdditionalFinishSnapshot_ -
                                    perMOPNPointMinted) *
                                    cData.AdditionalMOPNPoints) /
                                    cData.OnMapNftNumber) <<
                                144;
                        }
                        unpacked -= cData.AdditionalMOPNPoint << 48;
                    } else {
                        amount += (((perMOPNPointMintedDiff *
                            cData.AdditionalMOPNPoints) * 5) / 100);
                        unpacked +=
                            (((perMOPNPointMinted) *
                                cData.AdditionalMOPNPoints) /
                                cData.OnMapNftNumber) <<
                            144;
                    }
                }

                unpacked += amount << 192;

                emit CollectionMTMinted(collectionAddress, amount);
            } else {
                if (
                    cData.AdditionalMOPNPoint > 0 &&
                    AdditionalFinishSnapshot() > 0
                ) {
                    unpacked -= cData.AdditionalMOPNPoint << 48;
                }
            }

            CollectionsData[collectionAddress] = unpacked;
        }
    }

    function claimCollectionMT(
        address collectionAddress
    ) public returns (uint256 amount) {
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
            CollectionsData[collectionAddress] -= amount << 192;
            MiningDataExt += (amount << 64) | amount;
        }
    }

    function settleCollectionMOPNPoint(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) {
        uint256 point = getCollectionMOPNPoint(collectionAddress);
        uint256 lastPoint = uint24(CollectionsData[collectionAddress] >> 72);
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
                (lastPoint << 72) +
                (point << 72);
        }
    }

    function settleCollectionMining(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) returns (uint256) {
        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        return claimCollectionMT(collectionAddress);
    }

    function accountClaimAvailable(address account) public view returns (bool) {
        return
            getAccountSettledMT(account) > 0 ||
            getAccountCoordinate(account) > 0;
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
        return uint64(AccountsData[account] >> 128);
    }

    function getAccountPerCollectionNFTMinted(
        address account
    ) public view returns (uint256) {
        return uint48(AccountsData[account] >> 80);
    }

    /**
     * @notice get avatar settled per mopn token allocation weight minted mopn token number
     * @param account account wallet address
     */
    function getAccountPerMOPNPointMinted(
        address account
    ) public view returns (uint256) {
        return uint48(AccountsData[account] >> 32);
    }

    function getAccountCoordinate(
        address account
    ) public view returns (uint32) {
        return uint32(AccountsData[account]);
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
            OnMapMOPNPoint =
                (TileMath.getTileMOPNPoint(coordinate) +
                    IMOPNBomb(governance.bombContract()).balanceOf(
                        account,
                        2
                    )) *
                100;
        }
    }

    function _unpackedAccountData(
        uint256 packed
    ) private pure returns (AccountData memory accountData) {
        accountData.SettledMT = uint64(packed >> 128);
        accountData.PerCollectionNFTMinted = uint48(packed >> 80);
        accountData.PerMOPNPointMinted = uint48(packed >> 32);
        accountData.coordinate = uint32(packed);
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param account account wallet address
     */
    function calcAccountMT(
        address account
    ) public view returns (uint256 inbox) {
        inbox = getAccountSettledMT(account);
        uint256 AccountOnMapMOPNPoint = getAccountOnMapMOPNPoint(account);
        uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
            getAccountPerMOPNPointMinted(account);

        address collectionAddress = getAccountCollection(account);
        if (AccountPerMOPNPointMintedDiff > 0 && AccountOnMapMOPNPoint > 0) {
            uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(
                    collectionAddress
                ) - getAccountPerCollectionNFTMinted(account);
            inbox +=
                ((AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) * 90) /
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
    function settleAccountMT(
        address account,
        address collectionAddress
    ) public returns (bool) {
        uint256 unpacked = AccountsData[account];
        AccountData memory aData = _unpackedAccountData(unpacked);
        uint256 perMOPNPointMintedDiff = PerMOPNPointMinted() -
            aData.PerMOPNPointMinted;

        if (perMOPNPointMintedDiff > 0) {
            if (aData.coordinate > 0) {
                uint256 AccountOnMapMOPNPoint = getAccountOnMapMOPNPoint(
                    account
                );
                uint256 AccountPerCollectionNFTMintedDiff = getPerCollectionNFTMinted(
                        collectionAddress
                    ) - aData.PerCollectionNFTMinted;

                uint256 amount = perMOPNPointMintedDiff *
                    AccountOnMapMOPNPoint +
                    (
                        AccountPerCollectionNFTMintedDiff > 0
                            ? AccountPerCollectionNFTMintedDiff
                            : 0
                    );

                uint32 LandId = getTileLandId(aData.coordinate);
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
                unpacked +=
                    (amount << 128) |
                    (AccountPerCollectionNFTMintedDiff << 80) |
                    (perMOPNPointMintedDiff << 32);
            } else {
                unpacked += (perMOPNPointMintedDiff << 32);
            }
            AccountsData[account] = unpacked;
        }

        return aData.coordinate > 0;
    }

    /**
     * @notice redeem account unclaimed minted mopn token
     * @param account account wallet address
     */
    function settleAndClaimAccountMT(
        address account
    ) public onlyMT returns (uint256) {
        settlePerMOPNPointMinted();
        address collectionAddress = getAccountCollection(account);
        settleCollectionMT(collectionAddress);
        settleAccountMT(account, collectionAddress);
        return _claimAccountMT(account);
    }

    function claimAccountMT(
        address account
    ) public onlyMOPNData returns (uint256) {
        return _claimAccountMT(account);
    }

    function _claimAccountMT(
        address account
    ) internal returns (uint256 amount) {
        amount = getAccountSettledMT(account);
        if (amount > 0) {
            AccountsData[account] -= amount << 128;
        }
    }

    /**
     * @notice get Land holder settled minted unclaimed mopn token
     * @param LandId MOPN Land Id
     */
    function getLandIdSettledMT(uint32 LandId) public view returns (uint256) {
        return uint96(LandIdMTs[LandId]);
    }

    function getLandIdAccount(uint32 LandId) public view returns (address) {
        return address(uint160(LandIdMTs[LandId] >> 96));
    }

    function registerLandAccount(address account) public {
        (
            address collectionAddress,
            uint256 tokenId
        ) = getQualifiedAccountCollection(account);
        require(
            collectionAddress == governance.landContract(),
            "not a land account"
        );
        AccountsData[account] += getLandIdSettledMT(uint32(tokenId)) << 128;
        LandIdMTs[uint32(tokenId)] = (uint256(uint160(account)) << 96);
    }

    function addMOPNPoint(
        address account,
        address collectionAddress,
        uint256 amount
    ) public onlyBomb {
        _addMOPNPoint(account, collectionAddress, amount);
    }

    function subMOPNPoint(
        address account,
        address collectionAddress,
        uint256 amount
    ) public onlyBomb {
        _subMOPNPoint(account, collectionAddress, amount);
    }

    /**
     * add on map mining mopn token allocation weight
     * @param account account wallet address
     * @param amount Points amount
     */
    function _addMOPNPoint(
        address account,
        address collectionAddress,
        uint256 amount
    ) internal {
        amount *= 100;
        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);

        if (!settleAccountMT(account, collectionAddress)) {
            uint256 collectinPoint = getCollectionMOPNPoint(collectionAddress);
            uint256 additionalMOPNPoint = getCollectionAdditionalMOPNPoint(
                collectionAddress
            );
            if (additionalMOPNPoint == 0) {
                MiningData += amount + collectinPoint;
            } else {
                MiningData += amount + collectinPoint + additionalMOPNPoint;
                MiningDataExt += additionalMOPNPoint << 192;
            }

            CollectionsData[collectionAddress] += (uint256(1) << 32) | amount;
        } else {
            MiningData += amount;
            CollectionsData[collectionAddress] += amount;
        }
    }

    /**
     * substruct on map mining mopn token allocation weight
     * @param account account wallet address
     */
    function _subMOPNPoint(
        address account,
        address collectionAddress,
        uint256 amount
    ) internal {
        amount *= 100;
        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        if (amount == 0) {
            settleAccountMT(account, collectionAddress);
            amount = getAccountOnMapMOPNPoint(account);
            uint256 collectinPoint = getCollectionMOPNPoint(collectionAddress);
            uint256 additionalMOPNPoint = getCollectionAdditionalMOPNPoint(
                collectionAddress
            );
            if (additionalMOPNPoint == 0) {
                MiningData -= amount + collectinPoint;
            } else {
                MiningData -= amount + collectinPoint + additionalMOPNPoint;
                MiningDataExt -= additionalMOPNPoint << 192;
            }

            CollectionsData[collectionAddress] -= (uint256(1) << 32) | amount;
        } else {
            settleAccountMT(account, collectionAddress);
            MiningData -= amount;
            CollectionsData[collectionAddress] -= amount;
        }
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
            (oldNFTOfferCoefficient << 128) +
            (newNFTOfferCoefficient << 128);
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
