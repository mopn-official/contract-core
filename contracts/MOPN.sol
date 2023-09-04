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

    uint256 public MTOutputPerBlock;
    uint256 public MTStepStartBlock;

    uint256 public immutable MTReduceInterval;
    uint256 public immutable MaxCollectionOnMapNum;
    uint256 public immutable MaxCollectionMOPNPoint;

    BitMaps.BitMap private tilesbitmap;

    /**
     * @notice Mining Data
     * @dev This includes the following data:
     * - uint48 TotalBuffMOPNPoints: bits 208-255
     * - uint64 TotalMOPNPoints: bits 144-207
     * - uint32 LastTickBlock: bits 112-143
     * - uint48 PerMOPNPointMinted: bits 64-111
     * - uint64 MTTotalMinted: bits 0-63
     */
    uint256 public MiningData;

    /// @notice MiningDataExt structure:
    /// - uint16 nextLandId: bits 208-223
    /// - uint48 AdditionalFinishSnapshot: bits 160-207
    /// - uint48 NFTOfferCoefficient: bits 112-159
    /// - uint48 TotalCollectionClaimed: bits 64-111
    /// - uint64 TotalMTStaking: bits 0-63
    uint256 public MiningDataExt;

    /// @notice CollectionData structure:
    /// - uint32 AdditionalMOPNPoint: bits 224-255
    /// - uint24 CollectionMOPNPoint: bits 200-223
    /// - uint24 OnMapMOPNPoints: bits 176-199
    /// - uint16 OnMapNftNumber: bits 160-175
    /// - uint48 PerCollectionNFTMinted: bits 112-159
    /// - uint48 PerMOPNPointMinted: bits 64-111
    /// - uint64 SettledMT: bits 0-63
    mapping(address => uint256) public CollectionsData;

    /// @notice AccountData structure:
    /// - uint32 LandId: bits 192-223
    /// - uint32 Coordinate: bits 160-191
    /// - uint48 PerCollectionNFTMinted: bits 112-159
    /// - uint48 PerMOPNPointMinted: bits 64-111
    /// - uint64 SettledMT: bits 0-63
    mapping(address => uint256) public AccountsData;

    mapping(uint32 => address) public LandAccounts;

    IMOPNGovernance public governance;

    constructor(
        address governance_,
        uint256 MTOutputPerBlock_,
        uint256 MTStepStartBlock_,
        uint256 MTReduceInterval_,
        uint256 MaxCollectionOnMapNum_,
        uint256 MaxCollectionMOPNPoint_
    ) {
        governance = IMOPNGovernance(governance_);
        MTOutputPerBlock = MTOutputPerBlock_;
        MTStepStartBlock = MTStepStartBlock_;
        MTReduceInterval = MTReduceInterval_;
        MaxCollectionOnMapNum = MaxCollectionOnMapNum_;
        MaxCollectionMOPNPoint = MaxCollectionMOPNPoint_;
        MiningData = MTStepStartBlock_ << 112;
        MiningDataExt = (10 ** 14) << 112;
    }

    function getGovernance() public view returns (address) {
        return address(governance);
    }

    function batchSetCollectionBuffMOPNPoints(
        address[] calldata collectionAddress,
        uint256[] calldata buffMOPNPoints
    ) public onlyOwner {
        require(
            collectionAddress.length == buffMOPNPoints.length,
            "params illegal"
        );
        for (uint256 i = 0; i < collectionAddress.length; i++) {
            CollectionsData[collectionAddress[i]] = buffMOPNPoints[i] << 224;
        }
    }

    function AdditionalMOPNPointFinish() public onlyOwner {
        require(AdditionalFinishSnapshot() == 0, "already finished");
        settlePerMOPNPointMinted();
        MiningDataExt += PerMOPNPointMinted() << 160;
        MiningData -= TotalBuffMOPNPoints() << 144;
    }

    function getQualifiedAccountCollection(
        address account
    ) public view returns (address) {
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

        return collectionAddress;
    }

    uint32[] neighbors = [9999, 1, 10000, 9999, 1, 10000];

    function neighbor(
        uint32 tileCoordinate,
        uint256 direction
    ) public view returns (uint32) {
        unchecked {
            if (direction < 1 || direction > 3) {
                return tileCoordinate + neighbors[direction];
            }
            return tileCoordinate - neighbors[direction];
        }
    }

    function get256bitmap(
        uint256 bitmap,
        uint256 index
    ) public pure returns (bool) {
        unchecked {
            return bitmap & (1 << index) != 0;
        }
    }

    function set256bitmap(
        uint256 bitmap,
        uint256 index
    ) public pure returns (uint256) {
        unchecked {
            bitmap |= (1 << index);
            return bitmap;
        }
    }

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        return
            IERC6551Registry(governance.ERC6551Registry()).createAccount(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt,
                initData
            );
    }

    /**
     * @notice an on map NFT move to a new tile
     * @param tileCoordinate move To coordinate
     */
    function moveTo(
        uint32 tileCoordinate,
        uint32 LandId,
        address[] memory tileAccounts
    ) public {
        address collectionAddress = getQualifiedAccountCollection(msg.sender);
        _moveTo(
            msg.sender,
            collectionAddress,
            tileCoordinate,
            LandId,
            tileAccounts
        );
    }

    function moveToByOwner(
        address account,
        uint32 tileCoordinate,
        uint32 LandId,
        address[] memory tileAccounts
    ) public {
        require(
            IMOPNERC6551Account(payable(account)).isOwner(msg.sender),
            "not account owner"
        );
        address collectionAddress = getQualifiedAccountCollection(account);
        _moveTo(
            account,
            collectionAddress,
            tileCoordinate,
            LandId,
            tileAccounts
        );
    }

    function _moveTo(
        address account,
        address collectionAddress,
        uint32 tileCoordinate,
        uint32 LandId,
        address[] memory tileAccounts
    ) internal {
        require(block.number >= MTStepStartBlock, "mopn is not open yet");
        TileMath.check(tileCoordinate);

        require(
            TileMath.distance(tileCoordinate, TileMath.LandCenterTile(LandId)) <
                6,
            "LandId error"
        );
        if (LandId > NextLandId()) {
            unchecked {
                MiningDataExt +=
                    (IMOPNLand(governance.landContract()).nextTokenId() -
                        NextLandId()) <<
                    208;
            }
            require(NextLandId() > LandId, "Land Not Open");
        }

        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        settleAccountMT(account, collectionAddress);

        uint256 dstBitMap;

        unchecked {
            if (tilesbitmap.get(tileCoordinate)) {
                require(
                    tileCoordinate == getAccountCoordinate(tileAccounts[0]),
                    "tile accounts error"
                );
                address tileAccountCollection = getAccountCollection(
                    tileAccounts[0]
                );
                require(
                    collectionAddress != tileAccountCollection,
                    "dst has ally"
                );

                dstBitMap += 1 << 100;
                bombATile(
                    account,
                    tileCoordinate,
                    tileAccounts[0],
                    tileAccountCollection
                );
            }

            tileCoordinate++;
            for (uint256 i = 0; i < 18; i++) {
                if (
                    !get256bitmap(dstBitMap, i) &&
                    tilesbitmap.get(tileCoordinate)
                ) {
                    require(
                        tileCoordinate ==
                            getAccountCoordinate(tileAccounts[i + 1]),
                        "tile accounts error"
                    );
                    if (tileAccounts[i + 1] != account) {
                        address tileAccountCollection = getAccountCollection(
                            tileAccounts[i + 1]
                        );
                        if (tileAccountCollection == collectionAddress) {
                            dstBitMap = set256bitmap(dstBitMap, 50);
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
                        } else {
                            dstBitMap += 1 << 100;

                            bombATile(
                                account,
                                tileCoordinate,
                                tileAccounts[i + 1],
                                tileAccountCollection
                            );
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

            if ((dstBitMap >> 100) > 0) {
                governance.burnBomb(msg.sender, 1, dstBitMap >> 100);
            }

            tileCoordinate -= 2;
        }

        uint32 orgCoordinate = getAccountCoordinate(account);
        uint256 collectionOnMapNum = getCollectionOnMapNum(collectionAddress);

        if (!get256bitmap(dstBitMap, 50)) {
            require(
                collectionOnMapNum == 0 ||
                    (orgCoordinate > 0 && collectionOnMapNum == 1),
                "linked account missing"
            );
        }

        uint256 tileMOPNPoint = TileMath.getTileMOPNPoint(tileCoordinate);
        if (orgCoordinate > 0) {
            emit AccountMove(account, LandId, orgCoordinate, tileCoordinate);
            tilesbitmap.unset(orgCoordinate);
            uint256 orgMOPNPoint = TileMath.getTileMOPNPoint(orgCoordinate);

            unchecked {
                if (tileMOPNPoint > orgMOPNPoint) {
                    tileMOPNPoint -= orgMOPNPoint;
                } else if (tileMOPNPoint < orgMOPNPoint) {
                    tileMOPNPoint = orgMOPNPoint - tileMOPNPoint;
                }

                MiningData += tileMOPNPoint << 144;
                CollectionsData[collectionAddress] += tileMOPNPoint << 176;
                AccountsData[account] =
                    AccountsData[account] -
                    ((uint256(getAccountLandId(account)) << 192) |
                        (uint256(orgCoordinate) << 160)) +
                    ((uint256(LandId) << 192) |
                        (uint256(tileCoordinate) << 160));
            }
        } else {
            require(
                collectionOnMapNum < MaxCollectionOnMapNum,
                "collection on map nft number overflow"
            );
            emit AccountJumpIn(account, LandId, tileCoordinate);
            unchecked {
                MiningData +=
                    (getCollectionAdditionalMOPNPoint(collectionAddress) <<
                        208) |
                    ((tileMOPNPoint +
                        getCollectionNFTMOPNPoint(collectionAddress)) << 144);

                CollectionsData[collectionAddress] +=
                    (tileMOPNPoint << 176) |
                    (uint256(1) << 160);

                AccountsData[account] +=
                    (uint256(LandId) << 192) |
                    (uint256(tileCoordinate) << 160);
            }
        }

        tilesbitmap.set(tileCoordinate);
    }

    function bombATile(
        address account,
        uint32 tileCoordinate,
        address tileAccount,
        address tileAccountCollection
    ) internal {
        //remove tile account
        tilesbitmap.unset(tileCoordinate);

        settleCollectionMT(tileAccountCollection);
        settleAccountMT(tileAccount, tileAccountCollection);

        uint256 accountOnMapMOPNPoint = TileMath.getTileMOPNPoint(
            tileCoordinate
        );

        unchecked {
            MiningData -=
                (getCollectionAdditionalMOPNPoint(tileAccountCollection) <<
                    208) |
                ((accountOnMapMOPNPoint +
                    getCollectionNFTMOPNPoint(tileAccountCollection)) << 144);

            CollectionsData[tileAccountCollection] -=
                (accountOnMapMOPNPoint << 176) |
                (uint256(1) << 160);

            AccountsData[tileAccount] = uint160(AccountsData[tileAccount]);
        }
        emit BombUse(account, tileAccount, tileCoordinate);
    }

    /**
     * get current mt produce per block
     * @param reduceTimes reduce times
     */
    function currentMTPPB(
        uint256 reduceTimes
    ) public view returns (uint256 MTPPB) {
        int128 reducePercentage = ABDKMath64x64.divu(997, 1000);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, MTOutputPerBlock);
    }

    function currentMTPPB() public view returns (uint256 MTPPB) {
        if (MTStepStartBlock > block.number) {
            return 0;
        }
        return currentMTPPB(MTReduceTimes());
    }

    function MTReduceTimes() public view returns (uint256) {
        return (block.number - MTStepStartBlock) / MTReduceInterval;
    }

    function calcPerMOPNPointMinted() public returns (uint256 mData) {
        mData = MiningData;
        uint256 lastTickBlock = uint32(mData >> 112);
        if (block.number > lastTickBlock) {
            uint256 reduceTimes = MTReduceTimes();
            uint256 totalMOPNPoints = uint64(mData >> 144);
            unchecked {
                if (totalMOPNPoints > 0) {
                    uint256 perMOPNPointMintDiff;
                    if (reduceTimes == 0) {
                        perMOPNPointMintDiff +=
                            ((block.number - lastTickBlock) *
                                MTOutputPerBlock) /
                            totalMOPNPoints;
                    } else {
                        uint256 nextReduceBlock = MTStepStartBlock +
                            MTReduceInterval;
                        for (uint256 i = 0; i <= reduceTimes; i++) {
                            perMOPNPointMintDiff +=
                                ((nextReduceBlock - lastTickBlock) *
                                    currentMTPPB(i)) /
                                totalMOPNPoints;
                            lastTickBlock = nextReduceBlock;
                            nextReduceBlock += MTReduceInterval;
                            if (nextReduceBlock > block.number) {
                                nextReduceBlock = block.number;
                            }
                        }
                    }
                    mData +=
                        ((block.number - uint32(mData >> 112)) << 112) |
                        ((perMOPNPointMintDiff) << 64) |
                        (perMOPNPointMintDiff * totalMOPNPoints);
                } else {
                    mData += (block.number - lastTickBlock) << 112;
                }
            }

            if (reduceTimes > 0) {
                MTOutputPerBlock = currentMTPPB(reduceTimes);
                MTStepStartBlock += reduceTimes * MTReduceInterval;
            }
        }
    }

    /**
     * @notice settle per mopn token allocation weight minted mopn token
     */
    function settlePerMOPNPointMinted() public {
        MiningData = calcPerMOPNPointMinted();
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

    function calcCollectionMT(
        address collectionAddress,
        uint256 mData
    ) public returns (uint256 cData) {
        cData = CollectionsData[collectionAddress];
        uint256 collectionPerMOPNPointMinted = uint48(cData >> 64);
        unchecked {
            uint256 collectionPerMOPNPointMintedDiff = uint48(mData >> 64) -
                collectionPerMOPNPointMinted;
            if (collectionPerMOPNPointMintedDiff > 0) {
                uint256 collectionOnMapNum = uint16(cData >> 160);
                uint256 AdditionalFinishSnapshot_ = AdditionalFinishSnapshot();
                if (AdditionalFinishSnapshot_ > collectionPerMOPNPointMinted) {
                    collectionPerMOPNPointMintedDiff =
                        AdditionalFinishSnapshot_ -
                        collectionPerMOPNPointMinted;
                }

                if (collectionOnMapNum > 0) {
                    uint256 collectionNFTMOPNPoints = collectionOnMapNum *
                        (uint32(cData >> 224) + uint24(cData >> 200));

                    uint256 amount = ((collectionPerMOPNPointMintedDiff *
                        (uint24(cData >> 176) + collectionNFTMOPNPoints)) * 5) /
                        100;

                    if (collectionNFTMOPNPoints > 0) {
                        cData +=
                            (((collectionPerMOPNPointMintedDiff *
                                collectionNFTMOPNPoints) /
                                collectionOnMapNum) << 112) |
                            (collectionPerMOPNPointMintedDiff << 64) |
                            amount;
                    } else {
                        cData +=
                            (collectionPerMOPNPointMintedDiff << 64) |
                            amount;
                    }

                    emit CollectionMTMinted(collectionAddress, amount);
                } else {
                    cData += collectionPerMOPNPointMintedDiff << 64;
                }

                if (AdditionalFinishSnapshot_ > collectionPerMOPNPointMinted) {
                    uint256 buffMOPNPoint = getCollectionAdditionalMOPNPoint(
                        collectionAddress
                    );
                    cData -= buffMOPNPoint << 224;
                    CollectionsData[collectionAddress] = cData;
                    cData = calcCollectionMT(collectionAddress, mData);
                }
            }
        }
    }

    /**
     * @notice mint collection mopn token
     * @param collectionAddress collection contract address
     */
    function settleCollectionMT(address collectionAddress) public {
        CollectionsData[collectionAddress] = calcCollectionMT(
            collectionAddress,
            MiningData
        );
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
        uint256 point = getCollectionMOPNPointFromStaking(collectionAddress);
        uint256 lastPoint = getCollectionMOPNPoint(collectionAddress);
        if (point != lastPoint) {
            if (point > lastPoint) {
                MiningData +=
                    (point - lastPoint) *
                    getCollectionOnMapNum(collectionAddress);
                CollectionsData[collectionAddress] += point - lastPoint;
            } else if (point < lastPoint) {
                MiningData -=
                    (lastPoint - point) *
                    getCollectionOnMapNum(collectionAddress);
                CollectionsData[collectionAddress] -= lastPoint - point;
            }
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
            OnMapMOPNPoint = TileMath.getTileMOPNPoint(coordinate);
        }
    }

    /**
     * @notice mint avatar mopn token
     * @param account account wallet address
     */
    function calcAccountMT(
        address account,
        uint256 cData
    ) public returns (uint256 aData) {
        aData = AccountsData[account];
        unchecked {
            uint256 accountPerMOPNPointMintedDiff = uint48(cData >> 64) -
                uint48(aData >> 64);
            if (accountPerMOPNPointMintedDiff > 0) {
                uint32 coordinate = getAccountCoordinate(account);
                if (coordinate > 0) {
                    uint256 accountOnMapMOPNPoint = TileMath.getTileMOPNPoint(
                        coordinate
                    );
                    uint256 accountPerCollectionNFTMintedDiff = uint48(
                        cData >> 112
                    ) - uint48(aData >> 112);

                    uint256 amount = accountPerMOPNPointMintedDiff *
                        accountOnMapMOPNPoint +
                        (
                            accountPerCollectionNFTMintedDiff > 0
                                ? accountPerCollectionNFTMintedDiff
                                : 0
                        );

                    uint32 LandId = getAccountLandId(account);
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
                    aData +=
                        (accountPerCollectionNFTMintedDiff << 112) |
                        (accountPerMOPNPointMintedDiff << 64) |
                        amount;
                } else {
                    aData += accountPerMOPNPointMintedDiff << 64;
                }
            }
        }
    }

    function settleAccountMT(
        address account,
        address collectionAddress
    ) public {
        AccountsData[account] = calcAccountMT(
            account,
            CollectionsData[collectionAddress]
        );
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

    // MiningData
    function TotalBuffMOPNPoints() public view returns (uint256) {
        return uint48(MiningData >> 208);
    }

    function TotalMOPNPoints() public view returns (uint256) {
        return uint64(MiningData >> 144);
    }

    function LastTickBlock() public view returns (uint256) {
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
        return uint16(MiningDataExt >> 208);
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
        return uint32(CollectionsData[collectionAddress] >> 224);
    }

    function getCollectionAdditionalMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            uint256(uint32(CollectionsData[collectionAddress] >> 224)) *
            getCollectionOnMapNum(collectionAddress);
    }

    function getCollectionMOPNPoint(
        address collectionAddress
    ) public view returns (uint256) {
        return uint24(CollectionsData[collectionAddress] >> 200);
    }

    function getCollectionMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            uint256(uint24(CollectionsData[collectionAddress] >> 200)) *
            getCollectionOnMapNum(collectionAddress);
    }

    function getCollectionOnMapMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return uint24(CollectionsData[collectionAddress] >> 176);
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

    function getCollectionNFTMOPNPoint(
        address collectionAddress
    ) public view returns (uint256) {
        return
            getCollectionMOPNPoint(collectionAddress) +
            getCollectionAdditionalMOPNPoint(collectionAddress);
    }

    function getCollectionNFTMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            getCollectionNFTMOPNPoint(collectionAddress) *
            getCollectionOnMapNum(collectionAddress);
    }

    /// AccountData
    function getAccountLandId(address account) public view returns (uint32) {
        return uint32(AccountsData[account] >> 192);
    }

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
