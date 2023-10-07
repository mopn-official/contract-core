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
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
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

    uint256 public immutable MTReduceInterval;
    uint256 public immutable MaxCollectionOnMapNum;
    uint256 public immutable MaxCollectionMOPNPoint;

    BitMaps.BitMap private tilesbitmap;

    /**
     * @notice Mining Data
     * @dev This includes the following data:
     * - uint64 TotalMOPNPoints: bits 144-207
     * - uint32 LastTickBlock: bits 112-143
     * - uint48 PerMOPNPointMinted: bits 64-111
     * - uint64 MTTotalMinted: bits 0-63
     */

    /// uint256 public MiningData;

    struct MiningDataStruct {
        uint64 TotalMOPNPoints;
        uint32 LastTickBlock;
        uint48 PerMOPNPointMinted;
        uint64 MTTotalMinted;
    }

    MiningDataStruct public MiningData;

    /// @notice MiningDataExt structure:
    /// - uint8  whiteListSwitch: bits 176-183
    /// - uint16 nextLandId: bits 160-175
    /// - uint48 NFTOfferCoefficient: bits 112-159
    /// - uint48 TotalCollectionClaimed: bits 64-111
    /// - uint64 TotalMTStaking: bits 0-63

    /// uint256 public MiningDataExt;

    struct MiningDataExtStruct {
        bool whiteListSwitch;
        uint32 MTOutputPerBlock;
        uint32 MTStepStartBlock;
        uint16 nextLandId;
        uint48 NFTOfferCoefficient;
        uint48 TotalCollectionClaimed;
        uint64 TotalMTStaking;
    }

    MiningDataExtStruct public MiningDataExt;

    /// @notice CollectionData structure:
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
        uint32 MTOutputPerBlock_,
        uint32 MTStepStartBlock_,
        uint256 MTReduceInterval_,
        uint256 MaxCollectionOnMapNum_,
        uint256 MaxCollectionMOPNPoint_
    ) {
        governance = IMOPNGovernance(governance_);
        MTReduceInterval = MTReduceInterval_;
        MaxCollectionOnMapNum = MaxCollectionOnMapNum_;
        MaxCollectionMOPNPoint = MaxCollectionMOPNPoint_;
        MiningData.LastTickBlock = MTStepStartBlock_;
        MiningDataExt.MTOutputPerBlock = MTOutputPerBlock_;
        MiningDataExt.MTStepStartBlock = MTStepStartBlock_;
        MiningDataExt.NFTOfferCoefficient = 10 ** 14;
    }

    function getGovernance() external view returns (address) {
        return address(governance);
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

    //@todo whitelist
    function collectionWhiteListRegistry(
        address collectionAddress,
        bytes32[] memory proof
    ) public {}

    /**
     * @notice an on map NFT move to a new tile
     * @param tileCoordinate move To coordinate
     */
    function moveTo(
        uint32 tileCoordinate,
        uint32 LandId,
        address[] memory tileAccounts
    ) external {
        address collectionAddress = getQualifiedAccountCollection(msg.sender);
        _moveTo(
            msg.sender,
            collectionAddress,
            tileCoordinate,
            LandId,
            tileAccounts
        );
    }

    function moveToNFT(
        address collectionAddress,
        uint256 tokenId,
        uint32 tileCoordinate,
        uint32 LandId,
        address[] memory tileAccounts,
        bytes calldata initData
    ) external {
        address account = IERC6551Registry(governance.ERC6551Registry())
            .createAccount(
                governance.ERC6551AccountProxy(),
                block.chainid,
                collectionAddress,
                tokenId,
                0,
                initData
            );
        require(
            IMOPNERC6551Account(payable(account)).isOwner(msg.sender),
            "not account owner"
        );
        _moveTo(
            account,
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
    ) external {
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
        require(
            block.number >= MiningDataExt.MTStepStartBlock,
            "mopn is not open yet"
        );
        tilecheck(tileCoordinate);

        require(
            tiledistance(tileCoordinate, tileAtLandCenter(LandId)) < 6,
            "LandId error"
        );
        if (LandId > MiningDataExt.nextLandId) {
            unchecked {
                MiningDataExt.nextLandId = uint16(
                    IMOPNLand(governance.landContract()).nextTokenId()
                );
            }
            require(MiningDataExt.nextLandId > LandId, "Land Not Open");
        }

        settlePerMOPNPointMinted();

        if (MiningDataExt.whiteListSwitch) {
            require(
                CollectionsData[collectionAddress] > 0,
                "collection not in white list"
            );
        }
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
                                k = 3 + i * 2;

                                dstBitMap |= (127 << k);
                            } else {
                                dstBitMap = set256bitmap(dstBitMap, k + 1);
                                dstBitMap = set256bitmap(dstBitMap, k + 2);
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
                    tileCoordinate = tileneighbor(tileCoordinate, i);
                } else {
                    tileCoordinate = tileneighbor(tileCoordinate, (i - 6) / 2);
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

        uint256 tileMOPNPoint = tilepoint(tileCoordinate);
        if (orgCoordinate > 0) {
            emit AccountMove(account, LandId, orgCoordinate, tileCoordinate);
            tilesbitmap.unset(orgCoordinate);
            uint256 orgMOPNPoint = tilepoint(orgCoordinate);

            unchecked {
                if (tileMOPNPoint > orgMOPNPoint) {
                    tileMOPNPoint -= orgMOPNPoint;
                    MiningData.TotalMOPNPoints += uint64(tileMOPNPoint);
                    CollectionsData[collectionAddress] += tileMOPNPoint << 176;
                } else if (tileMOPNPoint < orgMOPNPoint) {
                    tileMOPNPoint = orgMOPNPoint - tileMOPNPoint;
                    MiningData.TotalMOPNPoints -= uint64(tileMOPNPoint);
                    CollectionsData[collectionAddress] -= tileMOPNPoint << 176;
                }

                AccountsData[account] =
                    ((uint256(LandId) << 192) |
                        (uint256(tileCoordinate) << 160)) |
                    uint160(AccountsData[account]);
            }
        } else {
            require(
                collectionOnMapNum < MaxCollectionOnMapNum,
                "collection on map nft number overflow"
            );
            emit AccountJumpIn(account, LandId, tileCoordinate);
            unchecked {
                MiningData.TotalMOPNPoints += uint64(
                    tileMOPNPoint + getCollectionMOPNPoint(collectionAddress)
                );

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

        uint256 accountOnMapMOPNPoint = tilepoint(tileCoordinate);

        unchecked {
            MiningData.TotalMOPNPoints -= uint64(
                (accountOnMapMOPNPoint +
                    getCollectionMOPNPoint(tileAccountCollection))
            );

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
        return ABDKMath64x64.mulu(reducePower, MiningDataExt.MTOutputPerBlock);
    }

    function currentMTPPB() public view returns (uint256 MTPPB) {
        if (MiningDataExt.MTStepStartBlock > block.number) {
            return 0;
        }
        return currentMTPPB(MTReduceTimes());
    }

    function MTReduceTimes() public view returns (uint256) {
        return
            (block.number - MiningDataExt.MTStepStartBlock) / MTReduceInterval;
    }

    function calcPerMOPNPointMinted() public returns (uint256 mData) {
        if (block.number > MiningData.LastTickBlock) {
            uint256 reduceTimes = MTReduceTimes();
            unchecked {
                if (MiningData.TotalMOPNPoints > 0) {
                    uint256 perMOPNPointMintDiff;
                    if (reduceTimes == 0) {
                        perMOPNPointMintDiff +=
                            ((block.number - MiningData.LastTickBlock) *
                                MiningDataExt.MTOutputPerBlock) /
                            MiningData.TotalMOPNPoints;
                    } else {
                        uint256 nextReduceBlock = MiningDataExt
                            .MTStepStartBlock + MTReduceInterval;
                        uint256 lastTickBlock = MiningData.LastTickBlock;
                        for (uint256 i = 0; i <= reduceTimes; i++) {
                            perMOPNPointMintDiff +=
                                ((nextReduceBlock - lastTickBlock) *
                                    currentMTPPB(i)) /
                                MiningData.TotalMOPNPoints;
                            lastTickBlock = nextReduceBlock;
                            nextReduceBlock += MTReduceInterval;
                            if (nextReduceBlock > block.number) {
                                nextReduceBlock = block.number;
                            }
                        }
                    }
                    MiningData.PerMOPNPointMinted += uint48(
                        perMOPNPointMintDiff
                    );
                    MiningData.MTTotalMinted += uint64(
                        perMOPNPointMintDiff * MiningData.TotalMOPNPoints
                    );
                }

                MiningData.LastTickBlock = uint32(block.number);
            }

            if (reduceTimes > 0) {
                MiningDataExt.MTOutputPerBlock = uint32(
                    currentMTPPB(reduceTimes)
                );
                MiningDataExt.MTStepStartBlock += uint32(
                    reduceTimes * MTReduceInterval
                );
            }
        }
    }

    /**
     * @notice settle per mopn token allocation weight minted mopn token
     */
    function settlePerMOPNPointMinted() public {
        calcPerMOPNPointMinted();
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
        address collectionAddress
    ) public returns (uint256 cData) {
        cData = CollectionsData[collectionAddress];
        unchecked {
            uint256 collectionPerMOPNPointMintedDiff = MiningData
                .PerMOPNPointMinted - uint48(cData >> 64);
            if (collectionPerMOPNPointMintedDiff > 0) {
                uint256 collectionOnMapNum = uint16(cData >> 160);

                if (collectionOnMapNum > 0) {
                    uint256 collectionMOPNPoints = collectionOnMapNum *
                        uint24(cData >> 200);

                    uint256 amount = ((collectionPerMOPNPointMintedDiff *
                        (uint24(cData >> 176) + collectionMOPNPoints)) * 5) /
                        100;

                    if (collectionMOPNPoints > 0) {
                        cData +=
                            (((collectionPerMOPNPointMintedDiff *
                                collectionMOPNPoints) / collectionOnMapNum) <<
                                112) |
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
            }
        }
    }

    /**
     * @notice mint collection mopn token
     * @param collectionAddress collection contract address
     */
    function settleCollectionMT(address collectionAddress) public {
        CollectionsData[collectionAddress] = calcCollectionMT(
            collectionAddress
        );
    }

    function claimCollectionMT(
        address collectionAddress
    ) external returns (uint256 amount) {
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
            MiningDataExt.TotalCollectionClaimed += uint48(amount);
            MiningDataExt.TotalMTStaking += uint64(amount);
        }
    }

    function settleCollectionMOPNPoint(
        address collectionAddress
    ) external onlyCollectionVault(collectionAddress) {
        uint256 point = getCollectionMOPNPointFromStaking(collectionAddress);
        uint256 lastPoint = getCollectionMOPNPoint(collectionAddress);
        if (point != lastPoint) {
            if (point > lastPoint) {
                MiningData.TotalMOPNPoints += uint64(
                    (point - lastPoint) *
                        getCollectionOnMapNum(collectionAddress)
                );
                CollectionsData[collectionAddress] +=
                    (point - lastPoint) <<
                    200;
            } else {
                MiningData.TotalMOPNPoints -= uint64(
                    (lastPoint - point) *
                        getCollectionOnMapNum(collectionAddress)
                );
                CollectionsData[collectionAddress] -=
                    (lastPoint - point) <<
                    200;
            }
            emit CollectionPointChange(collectionAddress, point);
        }
    }

    function accountClaimAvailable(
        address account
    ) external view returns (bool) {
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
            OnMapMOPNPoint = tilepoint(coordinate);
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
                    uint256 accountOnMapMOPNPoint = tilepoint(coordinate);
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
    ) internal {
        AccountsData[account] = calcAccountMT(
            account,
            CollectionsData[collectionAddress]
        );
    }

    function batchsettleAccountMT(address[][] memory accounts) external {
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

    function batchClaimAccountMT(address[][] memory accounts) external {
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

    function claimAccountMT(address account, address to) external {
        if (getAccountCoordinate(account) > 0) {
            settlePerMOPNPointMinted();
            address collectionAddress = getAccountCollection(account);
            settleCollectionMT(collectionAddress);
            settleAccountMT(account, collectionAddress);
        }

        uint256 amount = _claimAccountMT(account);
        if (to == address(0) || to == account) {
            governance.mintMT(account, amount);
        } else {
            require(
                IMOPNERC6551Account(payable(account)).isOwner(to),
                "claim dst is not owner"
            );
            governance.mintMT(to, amount);
        }
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
        external
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
        MiningDataExt.NFTOfferCoefficient = uint48(newNFTOfferCoefficient);
    }

    function changeTotalMTStaking(
        address collectionAddress,
        uint256 direction,
        uint256 amount
    ) external onlyCollectionVault(collectionAddress) {
        if (direction > 0) {
            MiningDataExt.TotalMTStaking += uint64(amount);
        } else {
            MiningDataExt.TotalMTStaking -= uint64(amount);
        }
    }

    // MiningData
    function TotalMOPNPoints() public view returns (uint256) {
        return MiningData.TotalMOPNPoints;
    }

    function LastTickBlock() public view returns (uint256) {
        return MiningData.LastTickBlock;
    }

    function PerMOPNPointMinted() public view returns (uint256) {
        return MiningData.PerMOPNPointMinted;
    }

    function MTTotalMinted() public view returns (uint256) {
        return MiningData.MTTotalMinted;
    }

    // MiningDataExt
    function MTOutputPerBlock() external view returns (uint256) {
        return MiningDataExt.MTOutputPerBlock;
    }

    function MTStepStartBlock() external view returns (uint256) {
        return MiningDataExt.MTStepStartBlock;
    }

    function WhiteListSwitch() public view returns (bool) {
        return MiningDataExt.whiteListSwitch;
    }

    function NextLandId() public view returns (uint256) {
        return MiningDataExt.nextLandId;
    }

    function NFTOfferCoefficient() public view returns (uint256) {
        return MiningDataExt.NFTOfferCoefficient;
    }

    function TotalCollectionClaimed() public view returns (uint256) {
        return MiningDataExt.TotalCollectionClaimed;
    }

    function TotalMTStaking() public view returns (uint256) {
        return MiningDataExt.TotalMTStaking;
    }

    /// CollectionData
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

    uint32[] neighbors = [9999, 1, 10000, 9999, 1, 10000];

    function tileneighbor(
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

    function tilecheck(uint32 tileCoordinate) public pure {
        tileCoordinate = tileCoordinate / 10000 + (tileCoordinate % 10000);
        require(
            3000 > tileCoordinate && tileCoordinate > 1000,
            "coordinate  overflow"
        );
    }

    function tilepoint(
        uint32 tileCoordinate
    ) public pure returns (uint256 tile) {
        unchecked {
            if ((tileCoordinate / 10000) % 10 == 0) {
                if (tileCoordinate % 10 == 0) {
                    return 1500;
                }
                return 500;
            } else if (tileCoordinate % 10 == 0) {
                return 500;
            }
            return 100;
        }
    }

    function tiledistance(uint32 a, uint32 b) public pure returns (uint32 d) {
        unchecked {
            uint32 at = a / 10000;
            uint32 bt = b / 10000;
            d += at > bt ? at - bt : bt - at;
            at = a % 10000;
            bt = b % 10000;
            d += at > bt ? at - bt : bt - at;
            at = 3000 - a / 10000 - at;
            bt = 3000 - b / 10000 - bt;
            d += at > bt ? at - bt : bt - at;

            return d / 2;
        }
    }

    function tileAtLandCenter(uint256 LandId) public pure returns (uint32) {
        if (LandId == 0) {
            return 10001000;
        }
        unchecked {
            uint256 n = (Math.sqrt(9 + 12 * LandId) - 3) / 6;
            if ((3 * n * n + 3 * n) != LandId) {
                n++;
            }

            uint256 startTile = 10001000 - n * 49989;
            uint256 z = 3000 - startTile / 10000 - (startTile % 10000);

            n--;
            uint256 LandIdRingPos_ = LandId - (3 * n * n + 3 * n);
            n++;

            uint256 side = Math.ceilDiv(LandIdRingPos_, n);

            uint256 sidepos = 0;
            if (n > 1) {
                sidepos = (LandIdRingPos_ - 1) % n;
            }
            if (side == 1) {
                startTile = startTile + sidepos * 110000 - sidepos * 6;
            } else if (side == 2) {
                startTile = (2000 - z) * 10000 + (2000 - startTile / 10000);
                startTile = startTile + sidepos * 49989;
            } else if (side == 3) {
                startTile = (startTile % 10000) * 10000 + z;
                startTile = startTile - sidepos * 60005;
            } else if (side == 4) {
                startTile = 20002000 - startTile;
                startTile = startTile - sidepos * 109994;
            } else if (side == 5) {
                startTile = z * 10000 + startTile / 10000;
                startTile = startTile - sidepos * 49989;
            } else if (side == 6) {
                startTile = (2000 - (startTile % 10000)) * 10000 + (2000 - z);
                startTile = startTile + sidepos * 60005;
            }

            return uint32(startTile);
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
