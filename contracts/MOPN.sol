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
    uint24 public immutable MaxCollectionMOPNPoint;

    bytes32 private whiteListRoot;

    BitMaps.BitMap private tilesbitmap;

    uint48 public TotalMOPNPoints;
    uint32 public LastTickBlock;
    uint48 public PerMOPNPointMinted;
    uint64 public MTTotalMinted;
    uint64 public TotalMTStaking;
    uint32 public MTOutputPerBlock;
    uint32 public MTStepStartBlock;
    uint16 public nextLandId;
    uint48 public NFTOfferCoefficient;
    uint48 public TotalCollectionClaimed;

    bool public whiteListSwitch;

    mapping(address => CollectionDataStruct) public CDs;

    mapping(address => AccountDataStruct) public ADs;

    mapping(uint16 => address) public LandAccounts;

    IMOPNGovernance public governance;

    modifier onlyCollectionVault(address collectionAddress) {
        require(
            msg.sender == governance.getCollectionVault(collectionAddress),
            "only collection vault allowed"
        );
        _;
    }

    modifier onlyToken() {
        require(msg.sender == governance.tokenContract(), "only token allowed");
        _;
    }

    constructor(
        address governance_,
        uint32 MTOutputPerBlock_,
        uint32 MTStepStartBlock_,
        uint256 MTReduceInterval_,
        uint256 MaxCollectionOnMapNum_,
        uint24 MaxCollectionMOPNPoint_,
        bool whiteListSwitch_
    ) {
        governance = IMOPNGovernance(governance_);
        MTReduceInterval = MTReduceInterval_;
        MaxCollectionOnMapNum = MaxCollectionOnMapNum_;
        MaxCollectionMOPNPoint = MaxCollectionMOPNPoint_;
        LastTickBlock = MTStepStartBlock_;
        whiteListSwitch = whiteListSwitch_;
        MTOutputPerBlock = MTOutputPerBlock_;
        MTStepStartBlock = MTStepStartBlock_;
        NFTOfferCoefficient = 10 ** 13;
    }

    function getGovernance() external view returns (address) {
        return address(governance);
    }

    function whiteListSwitchChange(bool switchStatus) public onlyOwner {
        whiteListSwitch = switchStatus;
    }

    function whiteListRootUpdate(bytes32 root) public onlyOwner {
        whiteListRoot = root;
    }

    function checkAccountQualification(
        address account
    ) public view returns (address collectionAddress) {
        uint256 chainId;
        uint256 tokenId;
        (chainId, collectionAddress, tokenId) = IMOPNERC6551Account(
            payable(account)
        ).token();
        if (ADs[account].PerMOPNPointMinted == 0) {
            require(
                chainId == block.chainid,
                "not support cross chain account"
            );
            require(
                account == computeMOPNAccount(collectionAddress, tokenId),
                "not a mopn Account Implementation"
            );
        }
    }

    function computeMOPNAccount(
        address tokenContract,
        uint256 tokenId
    ) public view returns (address) {
        return
            IERC6551Registry(governance.ERC6551Registry()).account(
                governance.ERC6551AccountProxy(),
                block.chainid,
                tokenContract,
                tokenId,
                0
            );
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

        if (CDs[collectionAddress].PerMOPNPointMinted == 0) {
            CDs[collectionAddress].PerMOPNPointMinted = PerMOPNPointMinted;
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
        address account,
        uint24 tileCoordinate,
        uint16 LandId,
        address[] memory tileAccounts
    ) external {
        _moveTo(
            account,
            tileCoordinate,
            LandId,
            tileAccounts,
            checkAccountQualification(account)
        );
    }

    function moveToNFT(
        address collectionAddress,
        uint256 tokenId,
        uint24 tileCoordinate,
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
        _moveTo(
            account,
            tileCoordinate,
            LandId,
            tileAccounts,
            collectionAddress
        );
    }

    function _moveTo(
        address account,
        uint24 tileCoordinate,
        uint16 LandId,
        address[] memory tileAccounts,
        address collectionAddress
    ) internal {
        bool isOwner = IMOPNERC6551Account(payable(account)).isOwner(
            msg.sender
        );
        if (ADs[account].Coordinate > 0) {
            require(isOwner, "not account owner");
        }

        require(block.number >= MTStepStartBlock, "mopn is not open yet");
        tilecheck(tileCoordinate);

        require(
            tiledistance(tileCoordinate, tileAtLandCenter(LandId)) < 6,
            "LandId error"
        );
        if (LandId > nextLandId) {
            unchecked {
                nextLandId = uint16(
                    IMOPNLand(governance.landContract()).nextTokenId()
                );
            }
            require(nextLandId > LandId, "Land Not Open");
        }

        if (whiteListSwitch) {
            require(
                CDs[collectionAddress].PerMOPNPointMinted > 0,
                "collection not register white list"
            );
        }

        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        settleAccountMT(account, collectionAddress);
        uint256 dstBitMap;

        unchecked {
            if (tilesbitmap.get(tileCoordinate)) {
                require(
                    tileCoordinate == ADs[tileAccounts[0]].Coordinate,
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
                        tileCoordinate == ADs[tileAccounts[i + 1]].Coordinate,
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

        require(
            get256bitmap(dstBitMap, 50) ||
                (CDs[collectionAddress].OnMapNftNumber == 0 ||
                    (ADs[account].Coordinate > 0 &&
                        CDs[collectionAddress].OnMapNftNumber == 1)),
            "linked account missing"
        );

        uint48 tileMOPNPoint = tilepoint(tileCoordinate);
        if (ADs[account].Coordinate > 0) {
            emit AccountMove(
                account,
                LandId,
                ADs[account].Coordinate,
                tileCoordinate
            );
            tilesbitmap.unset(ADs[account].Coordinate);
            uint48 orgMOPNPoint = tilepoint(ADs[account].Coordinate);

            unchecked {
                if (tileMOPNPoint > orgMOPNPoint) {
                    tileMOPNPoint -= orgMOPNPoint;
                    TotalMOPNPoints += tileMOPNPoint;
                    CDs[collectionAddress].OnMapMOPNPoints += tileMOPNPoint;
                } else if (tileMOPNPoint < orgMOPNPoint) {
                    tileMOPNPoint = orgMOPNPoint - tileMOPNPoint;
                    TotalMOPNPoints -= tileMOPNPoint;
                    CDs[collectionAddress].OnMapMOPNPoints -= tileMOPNPoint;
                }
            }
        } else {
            require(
                CDs[collectionAddress].OnMapNftNumber < MaxCollectionOnMapNum,
                "collection on map nft number overflow"
            );
            emit AccountJumpIn(
                account,
                LandId,
                tileCoordinate,
                isOwner ? address(0) : msg.sender
            );
            unchecked {
                TotalMOPNPoints +=
                    tileMOPNPoint +
                    CDs[collectionAddress].CollectionMOPNPoint;

                CDs[collectionAddress].OnMapMOPNPoints += tileMOPNPoint;
                CDs[collectionAddress].OnMapNftNumber++;
            }
        }

        ADs[account].LandId = LandId;
        ADs[account].Coordinate = tileCoordinate;
        if (!isOwner) {
            ADs[account].AgentPlacer = msg.sender;
        }

        tilesbitmap.set(tileCoordinate);
    }

    function bombATile(
        address account,
        uint24 tileCoordinate,
        address tileAccount,
        address tileAccountCollection
    ) internal {
        tilesbitmap.unset(tileCoordinate);

        settleCollectionMT(tileAccountCollection);
        settleAccountMT(tileAccount, tileAccountCollection);

        uint48 accountOnMapMOPNPoint = tilepoint(tileCoordinate);

        unchecked {
            TotalMOPNPoints -=
                accountOnMapMOPNPoint +
                CDs[tileAccountCollection].CollectionMOPNPoint;

            CDs[tileAccountCollection].OnMapMOPNPoints -= accountOnMapMOPNPoint;
            CDs[tileAccountCollection].OnMapNftNumber--;

            ADs[tileAccount].LandId = 0;
            ADs[tileAccount].Coordinate = 0;
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

    function settlePerMOPNPointMinted() public {
        if (block.number > LastTickBlock) {
            uint256 reduceTimes = MTReduceTimes();
            unchecked {
                if (TotalMOPNPoints > 0) {
                    uint256 perMOPNPointMintDiff;
                    if (reduceTimes == 0) {
                        perMOPNPointMintDiff +=
                            ((block.number - LastTickBlock) *
                                MTOutputPerBlock) /
                            TotalMOPNPoints;
                    } else {
                        uint256 nextReduceBlock = MTStepStartBlock +
                            MTReduceInterval;
                        uint256 lastTickBlock = LastTickBlock;
                        for (uint256 i = 0; i <= reduceTimes; i++) {
                            perMOPNPointMintDiff +=
                                ((nextReduceBlock - lastTickBlock) *
                                    currentMTPPB(i)) /
                                TotalMOPNPoints;
                            lastTickBlock = nextReduceBlock;
                            nextReduceBlock += MTReduceInterval;
                            if (nextReduceBlock > block.number) {
                                nextReduceBlock = block.number;
                            }
                        }
                    }
                    PerMOPNPointMinted += uint48(perMOPNPointMintDiff);
                    MTTotalMinted += uint64(
                        perMOPNPointMintDiff * TotalMOPNPoints
                    );
                }

                LastTickBlock = uint32(block.number);
            }

            if (reduceTimes > 0) {
                MTOutputPerBlock = uint32(currentMTPPB(reduceTimes));
                MTStepStartBlock += uint32(reduceTimes * MTReduceInterval);
            }
        }
    }

    function getCollectionMOPNPointFromStaking(
        address collectionAddress
    ) public view returns (uint24 point) {
        if (governance.getCollectionVault(collectionAddress) != address(0)) {
            point = uint24(
                (Math.sqrt(
                    IMOPNToken(governance.tokenContract()).balanceOf(
                        governance.getCollectionVault(collectionAddress)
                    ) / 10 ** 6
                ) * 3) / 10
            );
        }
        if (point > MaxCollectionMOPNPoint) {
            point = MaxCollectionMOPNPoint;
        }
    }

    function settleCollectionMT(address collectionAddress) public {
        unchecked {
            uint48 collectionPerMOPNPointMintedDiff = PerMOPNPointMinted -
                CDs[collectionAddress].PerMOPNPointMinted;
            if (collectionPerMOPNPointMintedDiff > 0) {
                if (CDs[collectionAddress].OnMapNftNumber > 0) {
                    uint48 collectionMOPNPoints = CDs[collectionAddress]
                        .OnMapNftNumber *
                        CDs[collectionAddress].CollectionMOPNPoint;

                    uint48 amount = (collectionPerMOPNPointMintedDiff *
                        (CDs[collectionAddress].OnMapMOPNPoints +
                            collectionMOPNPoints)) / 20;

                    if (collectionMOPNPoints > 0) {
                        CDs[collectionAddress].PerCollectionNFTMinted +=
                            (collectionPerMOPNPointMintedDiff *
                                collectionMOPNPoints) /
                            CDs[collectionAddress].OnMapNftNumber;
                    }

                    CDs[collectionAddress].SettledMT += amount;
                    emit CollectionMTMinted(collectionAddress, amount);
                }
                CDs[collectionAddress].PerMOPNPointMinted = PerMOPNPointMinted;
            }
        }
    }

    function claimCollectionMT(address collectionAddress) external {
        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        if (CDs[collectionAddress].SettledMT > 0) {
            address collectionVault = governance.getCollectionVault(
                collectionAddress
            );
            require(
                collectionVault != address(0),
                "collection vault not created"
            );
            IMOPNToken(governance.tokenContract()).mint(
                collectionVault,
                CDs[collectionAddress].SettledMT
            );

            TotalCollectionClaimed += CDs[collectionAddress].SettledMT;
            TotalMTStaking += CDs[collectionAddress].SettledMT;

            CDs[collectionAddress].SettledMT = 0;
        }
    }

    function settleCollectionMOPNPoint(
        address collectionAddress
    ) external onlyCollectionVault(collectionAddress) {
        uint24 point = getCollectionMOPNPointFromStaking(collectionAddress);
        if (point > CDs[collectionAddress].CollectionMOPNPoint) {
            TotalMOPNPoints +=
                (point - CDs[collectionAddress].CollectionMOPNPoint) *
                CDs[collectionAddress].OnMapNftNumber;
        } else if (point < CDs[collectionAddress].CollectionMOPNPoint) {
            TotalMOPNPoints -=
                (CDs[collectionAddress].CollectionMOPNPoint - point) *
                CDs[collectionAddress].OnMapNftNumber;
        }

        CDs[collectionAddress].CollectionMOPNPoint = point;
        emit CollectionPointChange(collectionAddress, point);
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param account account wallet address
     */
    function getAccountOnMapMOPNPoint(
        address account
    ) public view returns (uint256 OnMapMOPNPoint) {
        OnMapMOPNPoint = tilepoint(ADs[account].Coordinate);
    }

    function getAccountCollection(
        address account
    ) public view returns (address collectionAddress) {
        (, collectionAddress, ) = IMOPNERC6551Account(payable(account)).token();
    }

    /**
     * @notice mint avatar mopn token
     * @param account account wallet address
     */
    function settleAccountMT(
        address account,
        address collectionAddress
    ) internal {
        unchecked {
            uint48 accountPerMOPNPointMintedDiff = CDs[collectionAddress]
                .PerMOPNPointMinted - ADs[account].PerMOPNPointMinted;
            if (accountPerMOPNPointMintedDiff > 0) {
                if (ADs[account].Coordinate > 0) {
                    uint48 accountOnMapMOPNPoint = tilepoint(
                        ADs[account].Coordinate
                    );

                    uint48 amount = accountPerMOPNPointMintedDiff *
                        accountOnMapMOPNPoint +
                        (CDs[collectionAddress].PerCollectionNFTMinted -
                            ADs[account].PerCollectionNFTMinted);

                    address landAccount = LandAccounts[ADs[account].LandId];
                    if (landAccount == address(0)) {
                        landAccount = computeMOPNAccount(
                            governance.landContract(),
                            ADs[account].LandId
                        );
                        LandAccounts[ADs[account].LandId] = landAccount;
                    }
                    uint48 landamount = amount / 20;
                    ADs[landAccount].SettledMT += landamount;
                    emit LandHolderMTMinted(ADs[account].LandId, landamount);
                    if (ADs[account].AgentPlacer != address(0)) {
                        IMOPNToken(governance.tokenContract()).mint(
                            ADs[account].AgentPlacer,
                            amount / 10
                        );
                        amount = (amount * 8) / 10;
                        ADs[account].AgentPlacer = address(0);
                    } else {
                        amount = (amount * 9) / 10;
                    }

                    emit AccountMTMinted(account, amount);
                    ADs[account].SettledMT += amount;
                }
                ADs[account].PerMOPNPointMinted = CDs[collectionAddress]
                    .PerMOPNPointMinted;
                ADs[account].PerCollectionNFTMinted = CDs[collectionAddress]
                    .PerCollectionNFTMinted;
            }
        }
    }

    function batchClaimAccountMT(address[][] memory accounts) public {
        settlePerMOPNPointMinted();
        uint256 amount;
        IMOPNToken mt = IMOPNToken(governance.tokenContract());
        for (uint256 i = 0; i < accounts.length; i++) {
            for (uint256 k = 0; k < accounts[i].length; k++) {
                if (k == 0)
                    settleCollectionMT(getAccountCollection(accounts[i][k]));
                if (
                    IMOPNERC6551Account(payable(accounts[i][k])).isOwner(
                        msg.sender
                    )
                ) {
                    if (ADs[accounts[i][k]].Coordinate > 0) {
                        settleAccountMT(
                            accounts[i][k],
                            getAccountCollection(accounts[i][k])
                        );
                    }
                    if (ADs[accounts[i][k]].SettledMT > 0) {
                        amount += ADs[accounts[i][k]].SettledMT;
                        ADs[accounts[i][k]].SettledMT = 0;
                    }
                }
            }
        }
        if (amount > 0) mt.mint(msg.sender, amount);
    }

    function claimAccountMTTo(address account, address to) external onlyToken {
        _claimAccountMTTo(account, to);
    }

    function claimAccountMT(address account) external {
        _claimAccountMTTo(account, msg.sender);
    }

    function _claimAccountMTTo(address account, address to) internal {
        if (IMOPNERC6551Account(payable(account)).isOwner(to)) {
            if (ADs[account].Coordinate > 0) {
                settlePerMOPNPointMinted();
                address collectionAddress = getAccountCollection(account);
                settleCollectionMT(collectionAddress);
                settleAccountMT(account, collectionAddress);
            }

            if (ADs[account].SettledMT > 0) {
                IMOPNToken(governance.tokenContract()).mint(
                    to,
                    ADs[account].SettledMT
                );
                ADs[account].SettledMT = 0;
            }
        }
    }

    function NFTOfferAccept(
        address collectionAddress,
        uint256 price
    ) external onlyCollectionVault(collectionAddress) {
        uint64 totalMTStakingRealtime = (MTTotalMinted / 20) -
            TotalCollectionClaimed +
            TotalMTStaking;
        NFTOfferCoefficient = uint48(
            ((totalMTStakingRealtime + 1000000 - price) * NFTOfferCoefficient) /
                (totalMTStakingRealtime + 1000000)
        );
    }

    function changeTotalMTStaking(
        address collectionAddress,
        uint256 direction,
        uint256 amount
    ) external onlyCollectionVault(collectionAddress) {
        if (direction > 0) {
            TotalMTStaking += uint64(amount);
        } else {
            TotalMTStaking -= uint64(amount);
        }
    }

    /// CollectionData
    function getCollectionData(
        address collectionAddress
    ) public view returns (CollectionDataStruct memory) {
        return CDs[collectionAddress];
    }

    function getAccountData(
        address account
    ) public view returns (AccountDataStruct memory) {
        return ADs[account];
    }

    uint24[] neighbors = [9999, 1, 10000, 9999, 1, 10000];

    function tileneighbor(
        uint24 tileCoordinate,
        uint256 direction
    ) public view returns (uint24) {
        unchecked {
            if (direction < 1 || direction > 3) {
                return tileCoordinate + neighbors[direction];
            }
            return tileCoordinate - neighbors[direction];
        }
    }

    function tilecheck(uint24 tileCoordinate) public pure {
        tileCoordinate = tileCoordinate / 10000 + (tileCoordinate % 10000);
        require(
            3000 > tileCoordinate && tileCoordinate > 1000,
            "coordinate  overflow"
        );
    }

    function tilepoint(uint24 tileCoordinate) public pure returns (uint48) {
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

    function tiledistance(uint24 a, uint24 b) public pure returns (uint24 d) {
        unchecked {
            uint24 at = a / 10000;
            uint24 bt = b / 10000;
            d += at > bt ? at - bt : bt - at;
            at = a % 10000;
            bt = b % 10000;
            d += at > bt ? at - bt : bt - at;
            at = 3000 - a / 10000 - at;
            bt = 3000 - b / 10000 - bt;
            d += at > bt ? at - bt : bt - at;
            d /= 2;
        }
    }

    function tileAtLandCenter(uint256 LandId) public pure returns (uint24) {
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

            return uint24(startTile);
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
