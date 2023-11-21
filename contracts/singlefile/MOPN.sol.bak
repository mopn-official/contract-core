// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

interface IMOPN {
    struct CollectionDataStruct {
        uint24 CollectionMOPNPoint;
        uint48 OnMapMOPNPoints;
        uint16 OnMapNftNumber;
        uint48 PerCollectionNFTMinted;
        uint48 PerMOPNPointMinted;
        uint48 SettledMT;
    }

    struct AccountDataStruct {
        address AgentPlacer;
        uint16 LandId;
        uint24 Coordinate;
        uint48 PerMOPNPointMinted;
        uint48 SettledMT;
        uint48 PerCollectionNFTMinted;
    }

    /**
     * @notice This event emit when an avatar jump into the map
     * @param account account wallet address
     * @param LandId MOPN Land Id
     * @param tileCoordinate tile coordinate
     */
    event AccountJumpIn(
        address indexed account,
        uint16 indexed LandId,
        uint24 tileCoordinate,
        address agentPlacer
    );

    /**
     * @notice This event emit when an avatar move on map
     * @param account account wallet address
     * @param LandId MOPN Land Id
     * @param fromCoordinate tile coordinate
     * @param toCoordinate tile coordinate
     */
    event AccountMove(
        address indexed account,
        uint16 indexed LandId,
        uint24 fromCoordinate,
        uint24 toCoordinate
    );

    /**
     * @notice BombUse Event emit when a Bomb is used at a coordinate by an avatar
     * @param account account wallet address
     * @param victim the victim that bombed out of the map
     * @param tileCoordinate the tileCoordinate
     */
    event BombUse(
        address indexed account,
        address victim,
        uint24 tileCoordinate
    );

    event CollectionPointChange(
        address collectionAddress,
        uint256 CollectionPoint
    );

    event AccountMTMinted(address indexed account, uint256 amount);

    event CollectionMTMinted(address indexed collectionAddress, uint256 amount);

    event LandHolderMTMinted(uint16 indexed LandId, uint256 amount);

    function MTOutputPerBlock() external view returns (uint32);

    function MTStepStartBlock() external view returns (uint32);

    function MTReduceInterval() external view returns (uint256);

    function TotalMOPNPoints() external view returns (uint48);

    function LastTickBlock() external view returns (uint32);

    function PerMOPNPointMinted() external view returns (uint48);

    function MTTotalMinted() external view returns (uint64);

    function NFTOfferCoefficient() external view returns (uint48);

    function TotalCollectionClaimed() external view returns (uint48);

    function TotalMTStaking() external view returns (uint64);

    function currentMTPPB() external view returns (uint256);

    function currentMTPPB(uint256 reduceTimes) external view returns (uint256);

    function MTReduceTimes() external view returns (uint256);

    function settlePerMOPNPointMinted() external;

    function getCollectionData(
        address collectionAddress
    ) external view returns (CollectionDataStruct memory);

    function getCollectionMOPNPointFromStaking(
        address collectionAddress
    ) external view returns (uint24);

    function settleCollectionMT(address collectionAddress) external;

    function claimCollectionMT(address collectionAddress) external;

    function settleCollectionMOPNPoint(address collectionAddress) external;

    function getAccountData(
        address account
    ) external view returns (AccountDataStruct memory);

    function getAccountCollection(
        address account
    ) external view returns (address collectionAddress);

    function getAccountOnMapMOPNPoint(
        address account
    ) external view returns (uint256 OnMapMOPNPoint);

    function claimAccountMT(address account) external;

    function claimAccountMTTo(address account, address to) external;

    function changeTotalMTStaking(
        address collectionAddress,
        uint256 direction,
        uint256 amount
    ) external;

    function NFTOfferAccept(address collectionAddress, uint256 price) external;
}

interface IMOPNGovernance {
    function auctionHouseContract() external view returns (address);

    function mopnContract() external view returns (address);

    function bombContract() external view returns (address);

    function tokenContract() external view returns (address);

    function pointContract() external view returns (address);

    function landContract() external view returns (address);

    function dataContract() external view returns (address);

    function rentalContract() external view returns (address);

    function ERC6551Registry() external view returns (address);

    function ERC6551AccountProxy() external view returns (address);

    function ERC6551AccountHelper() external view returns (address);

    function getDefault6551AccountImplementation()
        external
        view
        returns (address);

    function checkImplementationExist(
        address implementation
    ) external view returns (bool);

    function createCollectionVault(
        address collectionAddress
    ) external returns (address);

    function getCollectionVaultIndex(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionVault(
        address collectionAddress
    ) external view returns (address);
}

/// @dev the ERC-165 identifier for this interface is `0x6faff5f1`
interface IERC6551Account {
    /**
     * @dev Allows the account to receive Ether
     *
     * Accounts MUST implement a `receive` function.
     *
     * Accounts MAY perform arbitrary logic to restrict conditions
     * under which Ether can be received.
     */
    receive() external payable;

    /**
     * @dev Returns the identifier of the non-fungible token which owns the account
     *
     * The return value of this function MUST be constant - it MUST NOT change
     * over time
     *
     * @return chainId       The EIP-155 ID of the chain the token exists on
     * @return tokenContract The contract address of the token
     * @return tokenId       The ID of the token
     */
    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId);

    /**
     * @dev Returns a value that SHOULD be modified each time the account changes state
     *
     * @return The current account state
     */
    function state() external view returns (uint256);

    /**
     * @dev Returns a magic value indicating whether a given signer is authorized to act on behalf of the account
     *
     * MUST return the bytes4 magic value 0x523e3260 if the given signer is valid
     *
     * By default, the holder of the non-fungible token the account is bound to MUST be considered a valid
     * signer
     *
     * Accounts MAY implement additional authorization logic which invalidates the holder as a
     * signer or grants signing permissions to other non-holder accounts
     *
     * @param  signer     The address to check signing authorization for
     * @param  context    Additional data used to determine whether the signer is valid
     * @return magicValue Magic value indicating whether the signer is valid
     */
    function isValidSigner(
        address signer,
        bytes calldata context
    ) external view returns (bytes4 magicValue);
}

/// @dev the ERC-165 identifier for this interface is `0x74420f4c`
interface IERC6551Executable {
    /**
     * @dev Executes a low-level operation if the caller is a valid signer on the account
     *
     * Reverts and bubbles up error if operation fails
     *
     * @param to        The target address of the operation
     * @param value     The Ether value to be sent to the target
     * @param data      The encoded operation calldata
     * @param operation A value indicating the type of operation to perform
     *
     * Accounts implementing this interface MUST accept the following operation parameter values:
     * - 0 = CALL
     * - 1 = DELEGATECALL
     * - 2 = CREATE
     * - 3 = CREATE2
     *
     * Accounts implementing this interface MAY support additional operations or restrict a signer's
     * ability to execute certain operations
     *
     * @return The result of the operation
     */
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation
    ) external payable returns (bytes memory);
}

interface IMOPNERC6551Account is IERC6551Account, IERC6551Executable {
    function executeProxy(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation,
        address msgsender
    ) external payable returns (bytes memory);

    function isOwner(address caller) external view returns (bool);

    function owner() external view returns (address);

    function nftowner() external view returns (address);

    function ownershipMode() external view returns (uint8);

    function ownerTransferTo(address to, uint40 endBlock) external;

    function renter() external view returns (address);

    function rentEndBlock() external view returns (uint40);
}

interface IERC6551Registry {
    /**
     * @dev The registry SHALL emit the AccountCreated event upon successful account creation
     */
    event AccountCreated(
        address account,
        address indexed implementation,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId,
        uint256 salt
    );

    /**
     * @dev Creates a token bound account for a non-fungible token.
     *
     * If account has already been created, returns the account address without calling create2.
     *
     * If initData is not empty and account has not yet been created, calls account with
     * provided initData after creation.
     *
     * Emits AccountCreated event.
     *
     * @return the address of the account
     */
    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address);

    /**
     * @dev Returns the computed token bound account address for a non-fungible token
     *
     * @return The computed address of the token bound account
     */
    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address);
}

interface IMOPNAuctionHouse {
    function buyBombFrom(address from, uint256 amount) external;
}

interface IMOPNLand is IERC721 {
    function auctionMint(address to, uint256 amount) external;

    function nextTokenId() external view returns (uint256);

    function MAX_SUPPLY() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface IMOPNBomb is IERC1155 {
    function mint(address to, uint256 id, uint256 amount) external;

    function burn(address from, uint256 id, uint256 amount) external;

    function transferOwnership(address newOwner) external;
}

interface IMOPNToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mopnburn(address account, uint256 amount) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) external;

    function transferOwnership(address newOwner) external;
}

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
    uint48 public whiteListOffTotalMOPNPoint;

    //total uint bits of above

    mapping(address => CollectionDataStruct) public CDs;

    mapping(address => AccountDataStruct) public ADs;

    mapping(uint16 => address) public LandAccounts;

    IMOPNGovernance public immutable governance;

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
        uint48 whiteListOffTotalMOPNPoint_,
        bytes32 whiteListRoot_
    ) {
        governance = IMOPNGovernance(governance_);
        MTReduceInterval = MTReduceInterval_;
        MaxCollectionOnMapNum = MaxCollectionOnMapNum_;
        MaxCollectionMOPNPoint = MaxCollectionMOPNPoint_;
        LastTickBlock = MTStepStartBlock_;
        whiteListOffTotalMOPNPoint = whiteListOffTotalMOPNPoint_;
        MTOutputPerBlock = MTOutputPerBlock_;
        MTStepStartBlock = MTStepStartBlock_;
        NFTOfferCoefficient = 10 ** 13;
        whiteListRoot = whiteListRoot_;
        PerMOPNPointMinted = 1;
    }

    function getGovernance() external view returns (address) {
        return address(governance);
    }

    function whiteListRootUpdate(bytes32 root) public onlyOwner {
        whiteListRoot = root;
    }

    function checkAccountQualification(
        address account
    ) public view returns (address collectionAddress) {
        try IMOPNERC6551Account(payable(account)).token() returns (
            uint256 chainId,
            address collectionAddress_,
            uint256 tokenId
        ) {
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
            collectionAddress = collectionAddress_;
        } catch (bytes memory) {
            require(false, "account error");
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
        uint48 OpenTotalMOPNPoint,
        bytes32[] memory proof
    ) public {
        require(
            OpenTotalMOPNPoint <= TotalMOPNPoints,
            "your collection is not open yet"
        );
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(abi.encode(collectionAddress, OpenTotalMOPNPoint))
            )
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
        bool isOwner;
        try IMOPNERC6551Account(payable(account)).isOwner(msg.sender) returns (
            bool isOwner_
        ) {
            isOwner = isOwner_;
            if (ADs[account].Coordinate > 0) {
                require(isOwner, "not account owner");
            }
        } catch (bytes memory) {
            require(false, "account owner error");
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

        if (whiteListOffTotalMOPNPoint > TotalMOPNPoints) {
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

                    IMOPNToken(governance.tokenContract()).mint(
                        IMOPNLand(governance.landContract()).ownerOf(
                            ADs[account].LandId
                        ),
                        amount / 20
                    );
                    emit LandHolderMTMinted(ADs[account].LandId, amount / 20);

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
                if (k == 0) {
                    settleCollectionMT(getAccountCollection(accounts[i][k]));
                }

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

import "@openzeppelin/contracts/utils/Multicall.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title Arsenal for Bomb
/// @author Cyanface<cyanface@outlook.com>
contract MOPNAuctionHouse is Multicall {
    IMOPNGovernance public governance;

    event BombSold(address indexed buyer, uint256 amount, uint256 price);

    uint256 public constant landPrice = 1000000000000;

    uint32 public landRoundStartBlock;

    uint64 public landRoundId;

    event LandSold(address indexed buyer, uint256 price);

    modifier onlyMOPN() {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.auctionHouseContract(),
            "not allowed"
        );
        _;
    }

    constructor(address governance_, uint32 landStartBlock) {
        governance = IMOPNGovernance(governance_);
        landRoundStartBlock = landStartBlock;
        landRoundId = 1;
    }

    /**
     * @notice buy the amount of bombs at current block's price
     * @param amount the amount of bombs
     */
    function buyBomb(uint256 amount) public {
        uint256 price = getBombCurrentPrice();

        if (price > 0) {
            IMOPNToken(governance.tokenContract()).mopnburn(
                msg.sender,
                price * amount
            );
        }

        _buyBomb(msg.sender, amount, price);
    }

    function buyBombFrom(address from, uint256 amount) public onlyMOPN {
        uint256 price = getBombCurrentPrice();

        if (price > 0) {
            IMOPNToken(governance.tokenContract()).mopnburn(
                from,
                price * amount
            );
        }

        _buyBomb(from, amount, price);
    }

    function _buyBomb(address buyer, uint256 amount, uint256 price) internal {
        IMOPNBomb(governance.bombContract()).mint(buyer, 1, amount);
        emit BombSold(buyer, amount, price);
    }

    /**
     * @notice get the current auction price by block.timestamp
     * @return price current auction price
     */
    function getBombCurrentPrice() public view returns (uint256) {
        return
            (IMOPN(governance.mopnContract()).currentMTPPB() * 50000) /
            (91 * IMOPNLand(governance.landContract()).nextTokenId());
    }

    /**
     * @notice get current Land Round Id
     * @return roundId round Id
     */
    function getLandRoundId() public view returns (uint64) {
        return landRoundId;
    }

    function getLandRoundStartBlock() public view returns (uint32) {
        return landRoundStartBlock;
    }

    /**
     * @notice buy one land at current block's price
     */
    function buyLand() public {
        uint256 price = getLandCurrentPrice();

        if (price > 0) {
            require(
                IMOPNToken(governance.tokenContract()).balanceOf(msg.sender) >
                    price,
                "MOPNToken not enough"
            );
            IMOPNToken(governance.tokenContract()).mopnburn(msg.sender, price);
        }

        _buyLand(msg.sender, price);
    }

    function _buyLand(address buyer, uint256 price) internal {
        require(block.number >= landRoundStartBlock, "auction not start");

        IMOPNLand(governance.landContract()).auctionMint(buyer, 1);

        emit LandSold(buyer, price);

        landRoundId++;
        landRoundStartBlock = uint32(block.number);
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getLandCurrentPrice() public view returns (uint256) {
        if (landRoundStartBlock >= block.number) {
            return landPrice;
        }
        return getLandPrice((block.number - landRoundStartBlock) / 5);
    }

    function getLandPrice(uint256 reduceTimes) public pure returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, landPrice);
    }

    /**
     * @notice a set of current round data
     * @return roundId round Id of current round
     * @return price
     */
    function getLandCurrentData()
        public
        view
        returns (uint256 roundId, uint256 price, uint256 startTimestamp)
    {
        roundId = getLandRoundId();
        price = getLandCurrentPrice();
        startTimestamp = landRoundStartBlock;
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes memory data
    ) public returns (bytes4) {
        require(
            msg.sender == governance.tokenContract(),
            "only accept mopn token"
        );

        if (data.length > 0) {
            (uint256 buyType, uint256 amount) = abi.decode(
                data,
                (uint256, uint256)
            );
            if (buyType == 1) {
                if (amount > 0) {
                    uint256 price = getBombCurrentPrice();
                    _checkTransferInAndRefund(from, value, price * amount);
                    _buyBomb(from, amount, price);
                }
            } else if (buyType == 2) {
                uint256 price = getLandCurrentPrice();
                _checkTransferInAndRefund(from, value, price);
                _buyLand(from, price);
            }
        }

        return IERC20Receiver.onERC20Received.selector;
    }

    function _checkTransferInAndRefund(
        address from,
        uint256 amount,
        uint256 charge
    ) internal {
        if (charge > 0) {
            require(amount >= charge, "mopn token not enough");
            IMOPNToken(governance.tokenContract()).burn(charge);
        }

        if (amount > charge) {
            IMOPNToken(governance.tokenContract()).transfer(
                from,
                amount - charge
            );
        }
    }
}

contract MOPNBomb is ERC1155, Multicall, Ownable {
    string public name;
    string public symbol;

    IMOPNGovernance governance;

    mapping(uint256 => string) private _uris;

    modifier onlyMOPN() {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.auctionHouseContract(),
            "not allowed"
        );
        _;
    }

    constructor(address governance_) ERC1155("") {
        name = "MOPN Bomb";
        symbol = "MOPNBOMB";
        governance = IMOPNGovernance(governance_);
    }

    /**
     * @notice setURI is used to set the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @param uri_ metadata uri corresponding to the token
     */
    function setURI(uint256 tokenId_, string calldata uri_) external onlyOwner {
        _uris[tokenId_] = uri_;
        emit URI(uri_, tokenId_);
    }

    /**
     * @notice uri is used to get the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @return metadata uri corresponding to the token
     */
    function uri(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        return _uris[tokenId_];
    }

    function mint(address to, uint256 id, uint256 amount) public onlyMOPN {
        _mint(to, id, amount, "");
    }

    function burn(address from, uint256 id, uint256 amount) public onlyMOPN {
        _burn(from, id, amount);
    }
}

contract MOPNCollectionVault is
    IMOPNCollectionVault,
    ERC20,
    IERC20Receiver,
    IERC721Receiver,
    Ownable
{
    address public immutable governance;

    uint8 OfferStatus;
    uint32 AuctionStartTimestamp;
    uint64 OfferAcceptPrice;
    uint256 AuctionTokenId;

    constructor(address governance_) ERC20("MOPN VToken", "MVT") {
        governance = governance_;
    }

    function name() public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "MOPN VToken",
                    " #",
                    Strings.toString(
                        IMOPNGovernance(governance).getCollectionVaultIndex(
                            collectionAddress()
                        )
                    )
                )
            );
    }

    function symbol() public pure override returns (string memory) {
        return "MVT";
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function collectionAddress() public view returns (address) {
        return CollectionVaultLib.collectionAddress();
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getAuctionCurrentPrice() public view returns (uint256) {
        if (OfferStatus == 0) return 0;

        return getAuctionPrice((block.timestamp - AuctionStartTimestamp) / 60);
    }

    function getAuctionPrice(
        uint256 reduceTimes
    ) public view returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, OfferAcceptPrice * 10);
    }

    function getAuctionInfo() public view returns (NFTAuction memory auction) {
        auction.offerStatus = OfferStatus;
        auction.startTimestamp = AuctionStartTimestamp;
        auction.offerAcceptPrice = OfferAcceptPrice;
        auction.tokenId = AuctionTokenId;
        auction.currentPrice = getAuctionCurrentPrice();
    }

    function MT2VAmountRealtime(
        uint256 MTAmount,
        bool onReceived
    ) public view returns (uint256 VAmount) {
        if (totalSupply() == 0) {
            VAmount = MTBalanceRealtime();
        } else {
            VAmount =
                (totalSupply() * MTAmount) /
                MTBalanceRealtime() -
                (onReceived ? MTAmount : 0);
        }
    }

    function MT2VAmount(
        uint256 MTAmount,
        bool onReceived
    ) public view returns (uint256 VAmount) {
        uint256 balance = IMOPNToken(
            IMOPNGovernance(governance).tokenContract()
        ).balanceOf(address(this));
        if (totalSupply() == 0) {
            VAmount = balance;
        } else {
            VAmount =
                (totalSupply() * MTAmount) /
                (balance - (onReceived ? MTAmount : 0));
        }
    }

    function V2MTAmountRealtime(
        uint256 VAmount
    ) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = MTBalanceRealtime();
        } else {
            MTAmount = (MTBalanceRealtime() * VAmount) / totalSupply();
        }
    }

    function V2MTAmount(
        uint256 VAmount
    ) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = IMOPNToken(IMOPNGovernance(governance).tokenContract())
                .balanceOf(address(this));
        } else {
            MTAmount =
                (IMOPNToken(IMOPNGovernance(governance).tokenContract())
                    .balanceOf(address(this)) * VAmount) /
                totalSupply();
        }
    }

    function withdraw(uint256 amount) public {
        address collectionAddress_ = CollectionVaultLib.collectionAddress();
        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());
        mopn.claimCollectionMT(collectionAddress_);
        uint256 mtAmount = V2MTAmount(amount);
        require(mtAmount > 0, "zero to withdraw");
        IMOPNToken(IMOPNGovernance(governance).tokenContract()).transfer(
            msg.sender,
            mtAmount
        );
        _burn(msg.sender, amount);
        mopn.settleCollectionMOPNPoint(collectionAddress_);
        mopn.changeTotalMTStaking(collectionAddress_, 0, mtAmount);

        emit MTWithdraw(msg.sender, mtAmount, amount);
    }

    function getNFTOfferPrice() public view returns (uint256) {
        uint256 amount = MTBalanceRealtime();

        return
            (amount *
                IMOPN(IMOPNGovernance(governance).mopnContract())
                    .NFTOfferCoefficient()) / 10 ** 15;
    }

    function MTBalanceRealtime() public view returns (uint256 amount) {
        amount =
            IMOPNData(IMOPNGovernance(governance).dataContract())
                .calcCollectionSettledMT(
                    CollectionVaultLib.collectionAddress()
                ) +
            IMOPNToken(IMOPNGovernance(governance).tokenContract()).balanceOf(
                address(this)
            );
    }

    function MTBalance() public view returns (uint256 balance) {
        balance = IMOPNToken(IMOPNGovernance(governance).tokenContract())
            .balanceOf(address(this));
    }

    function acceptNFTOffer(uint256 tokenId) public {
        require(OfferStatus == 0, "last offer auction not finish");
        address collectionAddress_ = CollectionVaultLib.collectionAddress();
        IERC721(collectionAddress_).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            "0x"
        );

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        mopn.claimCollectionMT(collectionAddress_);

        uint256 offerPrice = (IMOPNToken(
            IMOPNGovernance(governance).tokenContract()
        ).balanceOf(address(this)) * mopn.NFTOfferCoefficient()) / 10 ** 15;

        IMOPNToken(IMOPNGovernance(governance).tokenContract()).transfer(
            msg.sender,
            offerPrice
        );

        AuctionTokenId = tokenId;
        OfferAcceptPrice = uint64(offerPrice);
        AuctionStartTimestamp = uint32(block.timestamp);
        OfferStatus = 1;

        mopn.settleCollectionMOPNPoint(collectionAddress_);
        mopn.changeTotalMTStaking(collectionAddress_, 0, offerPrice);

        mopn.NFTOfferAccept(collectionAddress_, offerPrice);

        emit NFTOfferAccept(msg.sender, tokenId, offerPrice);
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public returns (bytes4) {
        require(
            msg.sender == IMOPNGovernance(governance).tokenContract(),
            "only accept mopn token"
        );

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        address collectionAddress_ = CollectionVaultLib.collectionAddress();

        if (bytes32(data) == keccak256("acceptAuctionBid")) {
            require(OfferStatus == 1, "auction not exist");

            require(
                block.timestamp >= AuctionStartTimestamp,
                "auction not start"
            );

            uint256 price = getAuctionCurrentPrice();
            require(value >= price, "MOPNToken not enough");

            if (value > price) {
                IMOPNToken(IMOPNGovernance(governance).tokenContract())
                    .transfer(from, value - price);
                value = price;
            }
            uint256 burnAmount;
            if (price > 0) {
                burnAmount = price / 20;
                IMOPNToken(IMOPNGovernance(governance).tokenContract()).burn(
                    burnAmount
                );

                price = price - burnAmount;
            }

            mopn.claimCollectionMT(collectionAddress_);
            mopn.settleCollectionMOPNPoint(collectionAddress_);
            mopn.changeTotalMTStaking(collectionAddress_, 1, price);

            IERC721(collectionAddress_).safeTransferFrom(
                address(this),
                from,
                AuctionTokenId,
                "0x"
            );

            emit NFTAuctionAccept(from, AuctionTokenId, price + burnAmount);

            OfferStatus = 0;
            AuctionTokenId = 0;
            AuctionStartTimestamp = 0;
            OfferAcceptPrice = 0;
        } else {
            require(OfferStatus == 0, "no staking during auction");
            mopn.claimCollectionMT(collectionAddress_);

            uint256 vtokenAmount = MT2VAmount(value, true);
            require(vtokenAmount > 0, "need more mt to get at least 1 vtoken");
            _mint(from, vtokenAmount);
            mopn.settleCollectionMOPNPoint(collectionAddress_);
            mopn.changeTotalMTStaking(collectionAddress_, 1, value);

            emit MTDeposit(from, value, vtokenAmount);
        }

        return IERC20Receiver.onERC20Received.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract MOPNGovernance is Multicall, Ownable {
    uint256 public vaultIndex;
    event CollectionVaultCreated(
        address indexed collectionAddress,
        address indexed collectionVault
    );

    /// uint160 vaultAdderss + uint96 vaultIndex
    mapping(address => uint256) public CollectionVaults;

    address public ERC6551Registry;
    address public ERC6551AccountProxy;
    address public ERC6551AccountHelper;
    address public rentalContract;

    address[] public ERC6551AccountImplementations;

    function updateERC6551Contract(
        address ERC6551Registry_,
        address ERC6551AccountProxy_,
        address ERC6551AccountHelper_,
        address rentalContract_
    ) public onlyOwner {
        ERC6551Registry = ERC6551Registry_;
        ERC6551AccountProxy = ERC6551AccountProxy_;
        ERC6551AccountHelper = ERC6551AccountHelper_;
        rentalContract = rentalContract_;
    }

    function getDefault6551AccountImplementation()
        public
        view
        returns (address implementation)
    {
        if (ERC6551AccountImplementations.length > 0)
            implementation = ERC6551AccountImplementations[0];
    }

    function setDefault6551AccountImplementation(
        address implementation
    ) public onlyOwner {
        address[] memory temps;
        if (checkImplementationExist(implementation)) {
            temps = new address[](ERC6551AccountImplementations.length);
            uint256 i = 0;
            temps[i] = implementation;
            for (uint256 k = 0; k < ERC6551AccountImplementations.length; k++) {
                if (ERC6551AccountImplementations[k] == implementation)
                    continue;
                i++;
                temps[i] = ERC6551AccountImplementations[k];
            }
        } else {
            temps = new address[](ERC6551AccountImplementations.length + 1);
            temps[0] = implementation;
            for (uint256 k = 0; k < ERC6551AccountImplementations.length; k++) {
                temps[k + 1] = ERC6551AccountImplementations[k];
            }
        }
        ERC6551AccountImplementations = temps;
    }

    function add6551AccountImplementation(
        address implementation
    ) public onlyOwner {
        require(
            !checkImplementationExist(implementation),
            "implementation exist"
        );

        ERC6551AccountImplementations.push(implementation);
    }

    function del6551AccountImplementation(
        address implementation
    ) public onlyOwner {
        require(
            checkImplementationExist(implementation),
            "implementation not exist"
        );

        address[] memory temps;
        if (ERC6551AccountImplementations.length > 1) {
            temps = new address[](ERC6551AccountImplementations.length - 1);
            uint256 i = 0;
            for (uint256 k = 0; k < ERC6551AccountImplementations.length; k++) {
                if (ERC6551AccountImplementations[k] == implementation)
                    continue;
                temps[i] = ERC6551AccountImplementations[k];
                i++;
            }
        }
        ERC6551AccountImplementations = temps;
    }

    function checkImplementationExist(
        address implementation
    ) public view returns (bool) {
        for (uint256 i = 0; i < ERC6551AccountImplementations.length; i++) {
            if (ERC6551AccountImplementations[i] == implementation) return true;
        }
        return false;
    }

    address public mopnContract;
    address public bombContract;
    address public tokenContract;
    address public pointContract;
    address public landContract;
    address public dataContract;
    address public collectionVaultContract;

    address public auctionHouseContract;

    function updateMOPNContracts(
        address auctionHouseContract_,
        address mopnContract_,
        address bombContract_,
        address tokenContract_,
        address pointContract_,
        address landContract_,
        address dataContract_,
        address collectionVaultContract_
    ) public onlyOwner {
        auctionHouseContract = auctionHouseContract_;
        mopnContract = mopnContract_;
        bombContract = bombContract_;
        tokenContract = tokenContract_;
        pointContract = pointContract_;
        landContract = landContract_;
        dataContract = dataContract_;
        collectionVaultContract = collectionVaultContract_;
    }

    function createCollectionVault(
        address collectionAddress
    ) public returns (address) {
        require(
            CollectionVaults[collectionAddress] == 0,
            "collection vault exist"
        );

        address vaultAddress = _createCollectionVault(collectionAddress);
        CollectionVaults[collectionAddress] =
            (uint256(uint160(vaultAddress)) << 96) |
            vaultIndex;
        emit CollectionVaultCreated(collectionAddress, vaultAddress);
        vaultIndex++;
        return vaultAddress;
    }

    function _createCollectionVault(
        address collectionAddress
    ) internal returns (address) {
        bytes memory code = CollectionVaultBytecodeLib.getCreationCode(
            collectionVaultContract,
            collectionAddress,
            0
        );

        address _account = Create2.computeAddress(bytes32(0), keccak256(code));

        if (_account.code.length != 0) return _account;

        _account = Create2.deploy(0, bytes32(0), code);
        return _account;
    }

    function getCollectionVault(
        address collectionAddress
    ) public view returns (address) {
        return address(uint160(CollectionVaults[collectionAddress] >> 96));
    }

    function getCollectionVaultIndex(
        address collectionAddress
    ) public view returns (uint256) {
        return uint96(CollectionVaults[collectionAddress]);
    }

    function computeCollectionVault(
        address collectionAddress
    ) public view returns (address) {
        bytes memory code = CollectionVaultBytecodeLib.getCreationCode(
            collectionVaultContract,
            collectionAddress,
            0
        );

        return Create2.computeAddress(bytes32(0), keccak256(code));
    }
}

contract MOPNToken is ERC20Burnable, Multicall {
    /**
     * @dev Magic value to be returned by ERC20Receiver upon successful reception of token(s)
     * @dev Equal to `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`,
     *      which can be also obtained as `ERC20Receiver(0).onERC20Received.selector`
     */
    bytes4 private constant ERC20_RECEIVED = 0x4fc35859;

    IMOPNGovernance governance;

    modifier onlyMOPN() {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.auctionHouseContract() ||
                msg.sender == 0x3FFE98b5c1c61Cc93b684B44aA2373e1263Dd4A4 ||
                msg.sender == 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // remove before prod
            "MOPNToken: Only MOPN contract can call this function"
        );
        _;
    }

    constructor(address governance_) ERC20("MOPN Token", "MT") {
        governance = IMOPNGovernance(governance_);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public onlyMOPN {
        _mint(to, amount);
    }

    function mopnburn(address from, uint256 amount) public onlyMOPN {
        _burn(from, amount);
    }

    function createCollectionVault(address collectionAddress) public {
        governance.createCollectionVault(collectionAddress);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) public {
        if (_from == msg.sender) {
            _transfer(_from, _to, _value);
        } else {
            transferFrom(_from, _to, _value);
        }

        // after the successful transfer – check if receiver supports
        // ERC20Receiver and execute a callback handler `onERC20Received`,
        // reverting whole transaction on any error:
        // check if receiver `_to` supports ERC20Receiver interface
        if (_to.code.length > 0) {
            // if `_to` is a contract – execute onERC20Received
            bytes4 response = IERC20Receiver(_to).onERC20Received(
                msg.sender,
                _from,
                _value,
                _data
            );

            // expected response is ERC20_RECEIVED
            require(response == ERC20_RECEIVED);
        }
    }

    function totalSupply() public view override returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        return
            mopn.MTTotalMinted() +
            (IMOPNData(governance.dataContract()).calcPerMOPNPointMinted() -
                mopn.PerMOPNPointMinted()) *
            mopn.TotalMOPNPoints();
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256 balance) {
        balance = super.balanceOf(account);
        balance += IMOPNData(governance.dataContract()).calcAccountMT(account);
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal virtual override {
        uint256 realbalance = super.balanceOf(from);
        IMOPN mopn = IMOPN(governance.mopnContract());
        IMOPN.AccountDataStruct memory accountData = mopn.getAccountData(from);
        if (
            accountData.PerMOPNPointMinted > 0 &&
            (accountData.AgentPlacer != address(0) || realbalance < amount)
        ) {
            mopn.claimAccountMTTo(from, from);
        }
    }
}
