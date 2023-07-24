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
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
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
    using TileMath for uint32;

    uint256 public constant MTReduceInterval = 604800;

    uint256 public MTOutputPerSec;
    uint256 public MTStepStartTimestamp;

    // Tile => uint160 account + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    /// @notice uint96 MTTotalMinted + uint32 LastTickTimestamp + uint64 PerMOPNPointMinted + uint64 TotalMOPNPoints
    uint256 public MiningData;

    /// @notice uint64 AdditionalFinishSnapshot + uint64 TotalAdditionalMOPNPoints + uint64 NFTOfferCoefficient + uint64 TotalMTStaking
    uint256 public MiningDataExt;

    /// @notice  uint64 settled MT + uint64 PerCollectionNFTMinted  + uint64 PerMOPNPointMinted + uint32 coordinate + uint32 TotalMOPNPoints
    mapping(address => uint256) public AccountsData;

    /// @notice uint64 mintedMT + uint48 PerCollectionNFTMinted + uint48 PerMOPNPointMinted + uint48 CollectionMOPNPoints + uint16 OnMapNftNumber + uint32 OnMapMOPNPoints
    mapping(address => uint256) public CollectionsData;

    mapping(address => uint256) public CollectionAdditionalMOPNPoints;

    /// @notice uint32 Land Id + uint64 settled MT
    mapping(uint32 => uint256) public LandIdMTs;

    /// @notice uint160 account address + uint64 settled MT
    mapping(address => uint256) public LandAccountMTs;

    IMOPNGovernance public governance;

    constructor(address governance_, uint256 MTStepStartTimestamp_) {
        MTOutputPerSec = 500000000;
        MTStepStartTimestamp = MTStepStartTimestamp_;
        governance = IMOPNGovernance(governance_);
        MiningData = MTStepStartTimestamp_ << 128;
        MiningDataExt = (10 ** 18) << 64;
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
            CollectionAdditionalMOPNPoints[
                collectionAddress[i]
            ] = additionalMOPNPoints[i];
        }
    }

    function AdditionalMOPNPointFinish() public onlyOwner {
        require(AdditionalFinishSnapshot() == 0, "already finished");
        settlePerMOPNPointMinted();
        MiningDataExt += PerMOPNPointMinted() << 192;
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

    /**
     * @notice an on map avatar move to a new tile
     * @param tileCoordinate NFT move To coordinate
     */
    function moveTo(uint32 tileCoordinate, uint32 LandId) public {
        tileCoordinate.check();
        (address collectionAddress, ) = getQualifiedAccountCollection(
            msg.sender
        );

        require(getTileAccount(tileCoordinate) == address(0), "dst Occupied");

        if (LandId == 0 || getTileLandId(tileCoordinate) != LandId) {
            require(
                tileCoordinate.distance(LandId.LandCenterTile()) < 6,
                "LandId error"
            );
            require(
                IMOPNLand(governance.landContract()).nextTokenId() > LandId,
                "Land Not Open"
            );
        }

        uint32 orgCoordinate = getAccountCoordinate(msg.sender);
        uint256 orgMOPNPoint;
        uint256 tileMOPNPoint = tileCoordinate.getTileMOPNPoint();
        if (orgCoordinate > 0) {
            tiles[tileCoordinate] = getTileLandId(tileCoordinate);
            orgMOPNPoint = orgCoordinate.getTileMOPNPoint();

            emit AccountMove(msg.sender, LandId, orgCoordinate, tileCoordinate);
        } else {
            tileMOPNPoint +=
                IMOPNBomb(governance.bombContract()).balanceOf(msg.sender, 2) *
                100;
            emit AccountJumpIn(msg.sender, LandId, tileCoordinate);
        }

        accountSet(msg.sender, collectionAddress, tileCoordinate, LandId);

        setAccountCoordinate(msg.sender, tileCoordinate);

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
    }

    /**
     * @notice throw a bomb to a tile
     * @param tileCoordinate bomb to tile coordinate
     */
    function bomb(uint32 tileCoordinate) public {
        tileCoordinate.check();
        getQualifiedAccountCollection(msg.sender);

        require(getAccountCoordinate(msg.sender) > 0, "NFT not on the map");

        address[] memory attackAccounts = new address[](7);
        uint32[] memory victimsCoordinates = new uint32[](7);
        uint32 orgTileCoordinate = tileCoordinate;

        uint256 killed;
        for (uint256 i = 0; i < 7; i++) {
            address attackAccount = getTileAccount(tileCoordinate);
            if (attackAccount != address(0) && attackAccount != msg.sender) {
                tiles[tileCoordinate] = getTileLandId(tileCoordinate);
                setAccountCoordinate(attackAccount, 0);
                attackAccounts[i] = attackAccount;
                victimsCoordinates[i] = tileCoordinate;
                _subMOPNPoint(
                    attackAccount,
                    getAccountCollection(attackAccount),
                    0
                );
                killed++;
            }

            if (i == 0) {
                tileCoordinate = tileCoordinate.neighbor(4);
            } else {
                tileCoordinate = tileCoordinate.neighbor(i - 1);
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

    /**
     * @notice avatar id occupied a tile
     * @param account avatar Id
     * @param tileCoordinate tile coordinate
     * @param LandId MOPN Land Id
     * @dev can only called by avatar contract
     */
    function accountSet(
        address account,
        address collectionAddress,
        uint32 tileCoordinate,
        uint32 LandId
    ) internal returns (bool collectionLinked) {
        tiles[tileCoordinate] =
            (uint256(uint160(account)) << 32) |
            uint256(LandId);
        tileCoordinate = tileCoordinate.neighbor(4);

        address tileAccount;
        address tileCollectionAddress;
        for (uint256 i = 0; i < 18; i++) {
            tileAccount = getTileAccount(tileCoordinate);
            if (tileAccount != address(0) && tileAccount != account) {
                tileCollectionAddress = getAccountCollection(tileAccount);
                require(
                    tileCollectionAddress == collectionAddress,
                    "tile has enemy"
                );
                collectionLinked = true;
            }

            if (i == 5) {
                tileCoordinate = tileCoordinate.neighbor(4).neighbor(5);
            } else if (i < 5) {
                tileCoordinate = tileCoordinate.neighbor(i);
            } else {
                tileCoordinate = tileCoordinate.neighbor((i - 6) / 2);
            }
        }

        if (collectionLinked == false) {
            uint256 collectionOnMapNum = getCollectionOnMapNum(
                collectionAddress
            );
            require(
                collectionOnMapNum == 0 ||
                    (getAccountCoordinate(account) > 0 &&
                        collectionOnMapNum == 1),
                "linked avatar missing"
            );
        }
    }

    function getGovernance() public view returns (address) {
        return address(governance);
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
        return uint48(MiningDataExt >> 192);
    }

    function TotalAdditionalMOPNPoints() public view returns (uint256) {
        return uint64(MiningDataExt >> 128);
    }

    function NFTOfferCoefficient() public view returns (uint256) {
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

    /**
     * @notice get collection on map mining mopn token allocation weight
     * @param collectionAddress collection contract adddress
     */
    function getCollectionMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return uint48(CollectionsData[collectionAddress] >> 48);
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

    function getCollectionAdditionalMOPNPoint(
        address collectionAddress
    ) public view returns (uint256) {
        return CollectionAdditionalMOPNPoints[collectionAddress];
    }

    function getCollectionAdditionalMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            CollectionAdditionalMOPNPoints[collectionAddress] *
            getCollectionOnMapNum(collectionAddress);
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
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param collectionAddress collection contract address
     */
    function calcCollectionMT(
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

    /**
     * @notice mint collection mopn token
     * @param collectionAddress collection contract address
     */
    function mintCollectionMT(address collectionAddress) public {
        uint256 CollectionPerMOPNPointMinted = getCollectionPerMOPNPointMinted(
            collectionAddress
        );
        uint256 CollectionPerMOPNPointMintedDiff = PerMOPNPointMinted() -
            CollectionPerMOPNPointMinted;
        if (CollectionPerMOPNPointMintedDiff > 0) {
            uint256 OnMapMOPNPoints = getCollectionOnMapMOPNPoints(
                collectionAddress
            );
            if (OnMapMOPNPoints > 0) {
                uint256 CollectionData = CollectionsData[collectionAddress];

                uint256 CollectionMOPNPoints = getCollectionMOPNPoints(
                    collectionAddress
                );

                uint256 amount = ((CollectionPerMOPNPointMintedDiff *
                    (OnMapMOPNPoints + CollectionMOPNPoints)) * 5) / 100;
                CollectionData += CollectionPerMOPNPointMintedDiff << 96;

                if (CollectionMOPNPoints > 0) {
                    CollectionData +=
                        ((CollectionPerMOPNPointMintedDiff *
                            CollectionMOPNPoints) /
                            getCollectionOnMapNum(collectionAddress)) <<
                        144;
                }

                uint256 AdditionalMOPNPoints = getCollectionAdditionalMOPNPoints(
                        collectionAddress
                    );
                if (AdditionalMOPNPoints > 0) {
                    uint256 AdditionalFinishSnapshot_ = AdditionalFinishSnapshot();
                    if (AdditionalFinishSnapshot_ > 0) {
                        if (
                            AdditionalFinishSnapshot_ >
                            CollectionPerMOPNPointMinted
                        ) {
                            amount +=
                                (((AdditionalFinishSnapshot_ -
                                    CollectionPerMOPNPointMinted) *
                                    AdditionalMOPNPoints) * 5) /
                                100;
                            CollectionData +=
                                (((AdditionalFinishSnapshot_ -
                                    CollectionPerMOPNPointMinted) *
                                    AdditionalMOPNPoints) /
                                    getCollectionOnMapNum(collectionAddress)) <<
                                144;
                            CollectionData -= AdditionalMOPNPoints << 32;
                        }
                        CollectionAdditionalMOPNPoints[collectionAddress] = 0;
                    } else {
                        amount += (((CollectionPerMOPNPointMintedDiff *
                            AdditionalMOPNPoints) * 5) / 100);
                        CollectionData +=
                            (((CollectionPerMOPNPointMintedDiff) *
                                AdditionalMOPNPoints) /
                                getCollectionOnMapNum(collectionAddress)) <<
                            144;
                    }
                }

                CollectionData += amount << 192;

                CollectionsData[collectionAddress] = CollectionData;
                emit CollectionMTMinted(collectionAddress, amount);
            } else {
                if (
                    CollectionAdditionalMOPNPoints[collectionAddress] > 0 &&
                    AdditionalFinishSnapshot() > 0
                ) {
                    CollectionAdditionalMOPNPoints[collectionAddress] = 0;
                }

                CollectionsData[collectionAddress] +=
                    CollectionPerMOPNPointMintedDiff <<
                    96;
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
            CollectionsData[collectionAddress] -= amount << 192;
            MiningDataExt += amount;
        }
    }

    function settleCollectionMOPNPoint(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) {
        uint256 point = getCollectionMOPNPoint(collectionAddress);
        uint256 collectionMOPNPoints;
        if (point > 0) {
            collectionMOPNPoints =
                point *
                getCollectionOnMapNum(collectionAddress);
        }
        uint256 preCollectionMOPNPoints = getCollectionMOPNPoints(
            collectionAddress
        );

        if (collectionMOPNPoints > preCollectionMOPNPoints) {
            MiningData += collectionMOPNPoints - preCollectionMOPNPoints;
            CollectionsData[collectionAddress] += ((collectionMOPNPoints -
                preCollectionMOPNPoints) << 48);
        } else if (collectionMOPNPoints < preCollectionMOPNPoints) {
            MiningData -= preCollectionMOPNPoints - collectionMOPNPoints;
            CollectionsData[collectionAddress] -= ((preCollectionMOPNPoints -
                collectionMOPNPoints) << 48);
        }

        emit SettleCollectionMOPNPoint(collectionAddress);
    }

    function settleCollectionMining(
        address collectionAddress
    ) public onlyCollectionVault(collectionAddress) {
        settlePerMOPNPointMinted();
        mintCollectionMT(collectionAddress);
        claimCollectionMT(collectionAddress);
    }

    function accountClaimAvailable(address account) public view returns (bool) {
        return
            getAccountSettledMT(account) > 0 ||
            getAccountCoordinate(account) > 0 ||
            getLandAccountSettledMT(account) > 0;
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
    function getAccountPerMOPNPointMinted(
        address account
    ) public view returns (uint256) {
        return uint64(AccountsData[account] >> 64);
    }

    function getAccountCoordinate(
        address account
    ) public view returns (uint32) {
        return uint32(AccountsData[account] >> 32);
    }

    function setAccountCoordinate(address account, uint32 coordinate) internal {
        AccountsData[account] =
            AccountsData[account] -
            (uint256(getAccountCoordinate(account)) << 32) +
            (uint256(coordinate) << 32);
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param account account wallet address
     */
    function getAccountTotalMOPNPoint(
        address account
    ) public view returns (uint256) {
        return uint32(AccountsData[account]);
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param account account wallet address
     */
    function calcAccountMT(
        address account
    ) public view returns (uint256 inbox) {
        inbox = getAccountSettledMT(account);
        uint256 AccountTotalMOPNPoint = getAccountTotalMOPNPoint(account);
        uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
            getAccountPerMOPNPointMinted(account);

        address collectionAddress = getAccountCollection(account);
        if (AccountPerMOPNPointMintedDiff > 0 && AccountTotalMOPNPoint > 0) {
            uint256 AccountPerCollectionNFTMintedDiff = getPerCollectionNFTMinted(
                    collectionAddress
                ) - getAccountPerCollectionNFTMinted(account);
            inbox +=
                ((AccountPerMOPNPointMintedDiff * AccountTotalMOPNPoint) * 90) /
                100;
            if (AccountPerCollectionNFTMintedDiff > 0) {
                inbox += (AccountPerCollectionNFTMintedDiff * 90) / 100;
            }
        }

        inbox += getLandAccountSettledMT(account);
    }

    /**
     * @notice mint avatar mopn token
     * @param account account wallet address
     */
    function mintAccountMT(address account) public returns (uint256) {
        uint256 AccountTotalMOPNPoint = getAccountTotalMOPNPoint(account);
        uint256 AccountPerMOPNPointMintedDiff = PerMOPNPointMinted() -
            getAccountPerMOPNPointMinted(account);
        if (AccountPerMOPNPointMintedDiff <= 0) {
            return AccountTotalMOPNPoint;
        }

        uint256 AccountPerCollectionNFTMintedDiff = getPerCollectionNFTMinted(
            getAccountCollection(account)
        ) - getAccountPerCollectionNFTMinted(account);

        uint256 amount;
        if (AccountTotalMOPNPoint > 0) {
            amount =
                AccountPerMOPNPointMintedDiff *
                AccountTotalMOPNPoint +
                (
                    AccountPerCollectionNFTMintedDiff > 0
                        ? AccountPerCollectionNFTMintedDiff
                        : 0
                );

            uint32 LandId = getTileLandId(getAccountCoordinate(account));
            uint256 landamount = (amount * 5) / 100;
            address landAccount = getLandIdAccount(LandId);
            if (landAccount != address(0)) {
                LandAccountMTs[landAccount] += landamount;
            } else {
                LandIdMTs[LandId] += landamount;
            }

            emit LandHolderMTMinted(LandId, landamount);

            amount = (amount * 90) / 100;

            emit AccountMTMinted(account, amount);
        }
        AccountsData[account] +=
            (amount << 192) |
            (AccountPerCollectionNFTMintedDiff << 128) |
            (AccountPerMOPNPointMintedDiff << 64);

        return AccountTotalMOPNPoint;
    }

    /**
     * @notice redeem account unclaimed minted mopn token
     * @param account account wallet address
     */
    function claimAccountMT(
        address account
    ) public onlyMT returns (uint256 amount) {
        settlePerMOPNPointMinted();
        mintCollectionMT(getAccountCollection(account));
        mintAccountMT(account);

        amount = getAccountSettledMT(account);
        if (amount > 0) {
            AccountsData[account] -= amount << 192;
        }

        uint256 landAmount = getLandAccountSettledMT(account);
        if (landAmount > 0) {
            LandAccountMTs[account] -= landAmount;
            amount += landAmount;
        }
    }

    /**
     * @notice get Land holder settled minted unclaimed mopn token
     * @param LandId MOPN Land Id
     */
    function getLandIdSettledMT(uint32 LandId) public view returns (uint256) {
        return uint64(LandIdMTs[LandId]);
    }

    function getLandIdAccount(uint32 LandId) public view returns (address) {
        return address(uint160(LandIdMTs[LandId] >> 64));
    }

    function getLandAccountSettledMT(
        address account
    ) public view returns (uint256) {
        return uint64(LandAccountMTs[account]);
    }

    function getLandAccountId(address account) public view returns (uint32) {
        return uint32(LandAccountMTs[account] >> 64);
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
        if (LandAccountMTs[account] == 0) {
            LandAccountMTs[account] =
                (tokenId << 64) |
                uint64(LandIdMTs[uint32(tokenId)]);
            LandIdMTs[uint32(tokenId)] = (uint256(uint160(account)) << 64);
        }
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
        mintCollectionMT(collectionAddress);
        uint256 exist = mintAccountMT(account);
        if (exist == 0) {
            uint256 collectinPoint = getCollectionMOPNPoint(collectionAddress);
            if (CollectionAdditionalMOPNPoints[collectionAddress] == 0) {
                MiningData += amount + collectinPoint;
            } else {
                MiningData +=
                    amount +
                    collectinPoint +
                    CollectionAdditionalMOPNPoints[collectionAddress];
                MiningDataExt +=
                    CollectionAdditionalMOPNPoints[collectionAddress] <<
                    128;
            }

            CollectionsData[collectionAddress] +=
                (collectinPoint << 48) |
                (uint256(1) << 32) |
                amount;
        } else {
            MiningData += amount;
            CollectionsData[collectionAddress] += amount;
        }
        AccountsData[account] += amount;
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
        mintCollectionMT(collectionAddress);
        if (amount == 0) {
            amount = mintAccountMT(account);
            uint256 collectinPoint = getCollectionMOPNPoint(collectionAddress);
            if (CollectionAdditionalMOPNPoints[collectionAddress] == 0) {
                MiningData -= amount + collectinPoint;
            } else {
                MiningData -=
                    amount +
                    collectinPoint +
                    CollectionAdditionalMOPNPoints[collectionAddress];
                MiningDataExt -=
                    CollectionAdditionalMOPNPoints[collectionAddress] <<
                    128;
            }

            CollectionsData[collectionAddress] -=
                (collectinPoint << 48) |
                (uint256(1) << 32) |
                amount;
        } else {
            mintAccountMT(account);
            MiningData -= amount;
            CollectionsData[collectionAddress] -= amount;
        }

        AccountsData[account] -= amount;
    }

    function NFTOfferAcceptNotify(
        address collectionAddress,
        uint256 price,
        uint256 tokenId
    ) public onlyCollectionVault(collectionAddress) {
        uint256 totalMTStaking = TotalMTStaking();
        MiningDataExt =
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
    ) public onlyCollectionVault(collectionAddress) {
        emit NFTAuctionAccept(collectionAddress, tokenId, price);
    }

    function changeTotalMTStaking(
        address collectionAddress,
        bool increase,
        uint256 amount,
        address operator
    ) public onlyCollectionVault(collectionAddress) {
        if (increase) {
            MiningDataExt += amount;
        } else {
            MiningDataExt -= amount;
        }

        emit VaultStakingChange(collectionAddress, operator, increase, amount);
    }

    modifier onlyCollectionVault(address collectionAddress) {
        require(
            msg.sender == governance.getCollectionVault(collectionAddress),
            "only collection vault allowed"
        );
        _;
    }

    modifier onlyBomb() {
        require(
            msg.sender == governance.bombContract() ||
                msg.sender == governance.mopnContract(),
            "only mopn or bomb allowed"
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
