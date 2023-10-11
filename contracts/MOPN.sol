// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./erc6551/interfaces/IMOPNERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNAuctionHouse.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IMOPNCollectionVault.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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
contract MOPN is IMOPN, Multicall, Ownable {
    using BitMaps for BitMaps.BitMap;

    uint256 public immutable MTReduceInterval;
    uint256 public immutable MaxCollectionOnMapNum;
    uint48 public immutable MaxCollectionMOPNPoint;

    bytes32 private whiteListRoot;

    BitMaps.BitMap private tilesbitmap;

    struct MiningDataStruct {
        uint48 TotalMOPNPoints;
        uint32 LastTickBlock;
        uint48 PerMOPNPointMinted;
        uint64 MTTotalMinted;
    }

    MiningDataStruct public MiningData;

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

    struct CollectionDataStruct {
        uint48 CollectionMOPNPoint;
        uint48 OnMapMOPNPoints;
        uint16 OnMapNftNumber;
        uint48 PerCollectionNFTMinted;
        uint48 PerMOPNPointMinted;
        uint48 SettledMT;
    }

    mapping(address => CollectionDataStruct) public CollectionsData;

    struct AccountDataStruct {
        uint16 LandId;
        uint32 Coordinate;
        uint48 PerCollectionNFTMinted;
        uint48 PerMOPNPointMinted;
        uint48 SettledMT;
        uint48 NFTOWnerSettledMT;
    }

    mapping(address => AccountDataStruct) public AccountsData;

    mapping(uint16 => address) public LandAccounts;

    IMOPNGovernance public governance;

    modifier onlyCollectionVault(address collectionAddress) {
        require(
            msg.sender == governance.getCollectionVault(collectionAddress),
            "only collection vault allowed"
        );
        _;
    }

    constructor(
        address governance_,
        uint32 MTOutputPerBlock_,
        uint32 MTStepStartBlock_,
        uint256 MTReduceInterval_,
        uint256 MaxCollectionOnMapNum_,
        uint48 MaxCollectionMOPNPoint_,
        bool whiteListSwitch
    ) {
        governance = IMOPNGovernance(governance_);
        MTReduceInterval = MTReduceInterval_;
        MaxCollectionOnMapNum = MaxCollectionOnMapNum_;
        MaxCollectionMOPNPoint = MaxCollectionMOPNPoint_;
        MiningData.LastTickBlock = MTStepStartBlock_;
        MiningDataExt.whiteListSwitch = whiteListSwitch;
        MiningDataExt.MTOutputPerBlock = MTOutputPerBlock_;
        MiningDataExt.MTStepStartBlock = MTStepStartBlock_;
        MiningDataExt.NFTOfferCoefficient = 10 ** 14;
    }

    function getGovernance() external view returns (address) {
        return address(governance);
    }

    function whiteListSwitchChange(bool switchStatus) public onlyOwner {
        MiningDataExt.whiteListSwitch = switchStatus;
    }

    function whiteListRootUpdate(bytes32 root) public onlyOwner {
        whiteListRoot = root;
    }

    function getQualifiedAccountCollection(
        address account
    ) public view returns (address) {
        (
            uint256 chainId,
            address collectionAddress,
            uint256 tokenId
        ) = IMOPNERC6551Account(payable(account)).token();

        if (AccountsData[account].PerMOPNPointMinted == 0) {
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

    function collectionWhiteListRegistry(
        address collectionAddress,
        bytes32[] memory proof
    ) public {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(collectionAddress)))
        );
        require(
            MerkleProof.verify(proof, whiteListRoot, leaf),
            "Invalid proof"
        );

        if (CollectionsData[collectionAddress].PerMOPNPointMinted == 0) {
            CollectionsData[collectionAddress].PerMOPNPointMinted = MiningData
                .PerMOPNPointMinted;
        }
    }

    function buyBomb(uint256 amount) external {
        IMOPNAuctionHouse(governance.auctionHouseContract()).buyBombFrom(
            msg.sender,
            amount
        );
    }

    /**
     * @notice an on map NFT move to a new tile
     * @param tileCoordinate move To coordinate
     */
    function moveTo(
        uint32 tileCoordinate,
        uint16 LandId,
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
        uint16 LandId,
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
        uint16 LandId,
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
        uint16 LandId,
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
                CollectionsData[collectionAddress].PerMOPNPointMinted > 0,
                "collection not in white list"
            );
        }
        settleCollectionMT(collectionAddress);
        settleAccountMT(account, collectionAddress);

        uint256 dstBitMap;

        unchecked {
            if (tilesbitmap.get(tileCoordinate)) {
                require(
                    tileCoordinate == AccountsData[tileAccounts[0]].Coordinate,
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
                            AccountsData[tileAccounts[i + 1]].Coordinate,
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
                IMOPNBomb(governance.bombContract()).burn(
                    msg.sender,
                    1,
                    dstBitMap >> 100
                );
            }
            tileCoordinate -= 2;
        }

        if (!get256bitmap(dstBitMap, 50)) {
            require(
                CollectionsData[collectionAddress].OnMapNftNumber == 0 ||
                    (AccountsData[account].Coordinate > 0 &&
                        CollectionsData[collectionAddress].OnMapNftNumber == 1),
                "linked account missing"
            );
        }

        uint48 tileMOPNPoint = tilepoint(tileCoordinate);
        if (AccountsData[account].Coordinate > 0) {
            emit AccountMove(
                account,
                LandId,
                AccountsData[account].Coordinate,
                tileCoordinate
            );
            tilesbitmap.unset(AccountsData[account].Coordinate);
            uint48 orgMOPNPoint = tilepoint(AccountsData[account].Coordinate);

            unchecked {
                if (tileMOPNPoint > orgMOPNPoint) {
                    tileMOPNPoint -= orgMOPNPoint;
                    MiningData.TotalMOPNPoints += tileMOPNPoint;
                    CollectionsData[collectionAddress]
                        .OnMapMOPNPoints += tileMOPNPoint;
                } else if (tileMOPNPoint < orgMOPNPoint) {
                    tileMOPNPoint = orgMOPNPoint - tileMOPNPoint;
                    MiningData.TotalMOPNPoints -= tileMOPNPoint;
                    CollectionsData[collectionAddress]
                        .OnMapMOPNPoints -= tileMOPNPoint;
                }
            }
        } else {
            require(
                CollectionsData[collectionAddress].OnMapNftNumber <
                    MaxCollectionOnMapNum,
                "collection on map nft number overflow"
            );
            emit AccountJumpIn(account, LandId, tileCoordinate);
            unchecked {
                MiningData.TotalMOPNPoints +=
                    tileMOPNPoint +
                    CollectionsData[collectionAddress].CollectionMOPNPoint;

                CollectionsData[collectionAddress]
                    .OnMapMOPNPoints += tileMOPNPoint;
                CollectionsData[collectionAddress].OnMapNftNumber++;
            }
        }

        AccountsData[account].LandId = LandId;
        AccountsData[account].Coordinate = tileCoordinate;

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

        uint48 accountOnMapMOPNPoint = tilepoint(tileCoordinate);

        unchecked {
            MiningData.TotalMOPNPoints -=
                accountOnMapMOPNPoint +
                CollectionsData[tileAccountCollection].CollectionMOPNPoint;

            CollectionsData[tileAccountCollection]
                .OnMapMOPNPoints -= accountOnMapMOPNPoint;
            CollectionsData[tileAccountCollection].OnMapNftNumber--;

            AccountsData[account].LandId = 0;
            AccountsData[account].Coordinate = 0;
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

    function settlePerMOPNPointMinted() public {
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

    function getCollectionMOPNPointFromStaking(
        address collectionAddress
    ) public view returns (uint48 point) {
        if (governance.getCollectionVault(collectionAddress) != address(0)) {
            point =
                uint48(
                    IMOPNCollectionVault(
                        governance.getCollectionVault(collectionAddress)
                    ).MTBalance()
                ) /
                10 ** 8;
        }
        if (point > MaxCollectionMOPNPoint) {
            point = MaxCollectionMOPNPoint;
        }
    }

    function settleCollectionMT(address collectionAddress) public {
        unchecked {
            uint48 collectionPerMOPNPointMintedDiff = MiningData
                .PerMOPNPointMinted -
                CollectionsData[collectionAddress].PerMOPNPointMinted;
            if (collectionPerMOPNPointMintedDiff > 0) {
                if (CollectionsData[collectionAddress].OnMapNftNumber > 0) {
                    uint48 collectionMOPNPoints = CollectionsData[
                        collectionAddress
                    ].OnMapNftNumber *
                        CollectionsData[collectionAddress].CollectionMOPNPoint;

                    uint48 amount = ((collectionPerMOPNPointMintedDiff *
                        (CollectionsData[collectionAddress].OnMapMOPNPoints +
                            collectionMOPNPoints)) * 5) / 100;

                    if (collectionMOPNPoints > 0) {
                        CollectionsData[collectionAddress]
                            .PerCollectionNFTMinted +=
                            (collectionPerMOPNPointMintedDiff *
                                collectionMOPNPoints) /
                            CollectionsData[collectionAddress].OnMapNftNumber;
                    }

                    CollectionsData[collectionAddress].SettledMT += amount;
                    emit CollectionMTMinted(collectionAddress, amount);
                }
                CollectionsData[collectionAddress]
                    .PerMOPNPointMinted = MiningData.PerMOPNPointMinted;
            }
        }
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
            IMOPNToken(governance.tokenContract()).mint(
                collectionVault,
                amount
            );
            CollectionsData[collectionAddress].SettledMT -= uint48(amount);
            MiningDataExt.TotalCollectionClaimed += uint48(amount);
            MiningDataExt.TotalMTStaking += uint64(amount);
        }
    }

    function settleCollectionMOPNPoint(
        address collectionAddress
    ) external onlyCollectionVault(collectionAddress) {
        uint48 point = getCollectionMOPNPointFromStaking(collectionAddress);
        if (point != CollectionsData[collectionAddress].CollectionMOPNPoint) {
            if (
                point > CollectionsData[collectionAddress].CollectionMOPNPoint
            ) {
                MiningData.TotalMOPNPoints +=
                    (point -
                        CollectionsData[collectionAddress]
                            .CollectionMOPNPoint) *
                    CollectionsData[collectionAddress].OnMapNftNumber;
            } else {
                MiningData.TotalMOPNPoints -=
                    (CollectionsData[collectionAddress].CollectionMOPNPoint -
                        point) *
                    CollectionsData[collectionAddress].OnMapNftNumber;
            }

            CollectionsData[collectionAddress].CollectionMOPNPoint = point;
            emit CollectionPointChange(collectionAddress, point);
        }
    }

    function accountClaimAvailable(
        address account
    ) external view returns (bool) {
        return
            AccountsData[account].SettledMT > 0 ||
            AccountsData[account].Coordinate > 0;
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
        OnMapMOPNPoint = tilepoint(AccountsData[account].Coordinate);
    }

    /**
     * @notice mint avatar mopn token
     * @param account account wallet address
     */
    function settleAccountMT(
        address account,
        address collectionAddress
    ) public {
        unchecked {
            uint48 accountPerMOPNPointMintedDiff = CollectionsData[
                collectionAddress
            ].PerMOPNPointMinted - AccountsData[account].PerMOPNPointMinted;
            if (accountPerMOPNPointMintedDiff > 0) {
                uint32 coordinate = getAccountCoordinate(account);
                if (coordinate > 0) {
                    uint48 accountOnMapMOPNPoint = tilepoint(coordinate);
                    uint48 accountPerCollectionNFTMintedDiff = CollectionsData[
                        collectionAddress
                    ].PerCollectionNFTMinted -
                        AccountsData[account].PerCollectionNFTMinted;

                    uint48 amount = accountPerMOPNPointMintedDiff *
                        accountOnMapMOPNPoint +
                        (
                            accountPerCollectionNFTMintedDiff > 0
                                ? accountPerCollectionNFTMintedDiff
                                : 0
                        );

                    address landAccount = LandAccounts[
                        AccountsData[account].LandId
                    ];
                    if (landAccount == address(0)) {
                        landAccount = getLandAccount(
                            AccountsData[account].LandId
                        );
                        LandAccounts[
                            AccountsData[account].LandId
                        ] = landAccount;
                    }
                    uint48 landamount = (amount * 5) / 100;
                    AccountsData[landAccount].SettledMT += landamount;

                    emit LandHolderMTMinted(
                        AccountsData[account].LandId,
                        landamount
                    );

                    amount = (amount * 90) / 100;

                    emit AccountMTMinted(account, amount);
                    AccountsData[account]
                        .PerCollectionNFTMinted += accountPerCollectionNFTMintedDiff;

                    AccountsData[account].SettledMT += amount;
                }
                AccountsData[account]
                    .PerMOPNPointMinted += accountPerMOPNPointMintedDiff;
            }
        }
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
        IMOPNToken(governance.tokenContract()).mint(msg.sender, amount);
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
            IMOPNToken(governance.tokenContract()).mint(account, amount);
        } else {
            require(
                IMOPNERC6551Account(payable(account)).isOwner(to),
                "claim dst is not owner"
            );
            IMOPNToken(governance.tokenContract()).mint(to, amount);
        }
    }

    function _claimAccountMT(
        address account
    ) internal returns (uint256 amount) {
        amount = AccountsData[account].SettledMT;
        if (amount > 0) {
            AccountsData[account].SettledMT = 0;
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
        return CollectionsData[collectionAddress].CollectionMOPNPoint;
    }

    function getCollectionMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return
            CollectionsData[collectionAddress].CollectionMOPNPoint *
            CollectionsData[collectionAddress].OnMapNftNumber;
    }

    function getCollectionOnMapMOPNPoints(
        address collectionAddress
    ) public view returns (uint256) {
        return CollectionsData[collectionAddress].OnMapMOPNPoints;
    }

    function getCollectionOnMapNum(
        address collectionAddress
    ) public view returns (uint256) {
        return CollectionsData[collectionAddress].OnMapNftNumber;
    }

    function getPerCollectionNFTMinted(
        address collectionAddress
    ) public view returns (uint256) {
        return CollectionsData[collectionAddress].PerCollectionNFTMinted;
    }

    function getCollectionPerMOPNPointMinted(
        address collectionAddress
    ) public view returns (uint256) {
        return CollectionsData[collectionAddress].PerMOPNPointMinted;
    }

    function getCollectionSettledMT(
        address collectionAddress
    ) public view returns (uint256) {
        return CollectionsData[collectionAddress].SettledMT;
    }

    /// AccountData
    function getAccountLandId(address account) public view returns (uint32) {
        return AccountsData[account].LandId;
    }

    function getAccountCoordinate(
        address account
    ) public view returns (uint32) {
        return AccountsData[account].Coordinate;
    }

    function getAccountPerCollectionNFTMinted(
        address account
    ) public view returns (uint256) {
        return AccountsData[account].PerCollectionNFTMinted;
    }

    /**
     * @notice get avatar settled per mopn token allocation weight minted mopn token number
     * @param account account wallet address
     */
    function getAccountPerMOPNPointMinted(
        address account
    ) public view returns (uint256) {
        return AccountsData[account].PerMOPNPointMinted;
    }

    /**
     * @notice get avatar settled unclaimed minted mopn token
     * @param account account wallet address
     */
    function getAccountSettledMT(
        address account
    ) public view returns (uint256) {
        return AccountsData[account].SettledMT;
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

    function tilepoint(uint32 tileCoordinate) public pure returns (uint48) {
        if (tileCoordinate == 0) {
            return 0;
        }
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
}
