// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IAvatar.sol";
import "./interfaces/IAuctionHouse.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IBomb.sol";
import "./interfaces/ILand.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @title Governance of MOPN
/// @author Cyanface<cyanface@outlook.com>
/// @dev Governance is all other MOPN contract's owner
contract Governance is Multicall, Ownable {
    uint256 public constant MTProducePerBlock = 600000000000;

    uint256 public constant MTProduceReduceInterval = 50000;

    uint256 public MTProduceStartBlock;

    /// @notice PerMTAWMinted * 10 ** 24 + LastPerMTAWMintedCalcBlock * 10 ** 12 + TotalMTAWs
    uint256 public MTProduceData;

    /// @notice MT Inbox * 10 ** 52 + Total Minted MT * 10 ** 32 + PerMTAWMinted * 10 ** 12 + TotalMTAWs
    mapping(uint256 => uint256) public AvatarMTs;

    mapping(uint256 => uint256) public CollectionMTs;

    mapping(uint32 => uint256) public LandHolderMTs;

    event AvatarMTMinted(uint256 indexed avatarId, uint256 amount);

    event CollectionMTMinted(uint256 indexed COID, uint256 amount);

    event MTClaimed(address indexed to, uint256 amount);

    constructor(uint256 MTProduceStartBlock_) {
        MTProduceStartBlock = MTProduceStartBlock_;
    }

    /**
     * @notice get settled Per MT Allocation Weight minted mopn token number
     */
    function getPerMTAWMinted() public view returns (uint256) {
        return MTProduceData / 10 ** 24;
    }

    /**
     * @notice get MT last minted settlement block number
     */
    function getLastPerMTAWMintedCalcBlock() public view returns (uint256) {
        return (MTProduceData % 10 ** 24) / 10 ** 12;
    }

    /**
     * @notice get total mopn token allocation weights
     */
    function getTotalMTAWs() public view returns (uint256) {
        return MTProduceData % 10 ** 12;
    }

    /**
     * add on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId mopn Land Id
     * @param amount EAW amount
     */
    function addMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) public onlyMap {
        _addMTAW(avatarId, COID, LandId, amount);
    }

    /**
     * substruct on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId mopn Land Id
     */
    function subMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId
    ) public onlyMap {
        _subMTAW(avatarId, COID, LandId);
    }

    uint256[] MTPPBMap = [
        600000000000,
        133576606537,
        29737849684,
        6620468402,
        1473899498,
        328130815,
        73050994,
        16263166,
        3620622,
        806043,
        179440,
        39941,
        8885,
        1970,
        431,
        87,
        13
    ];

    uint256 MTPPBZeroTriger = 8211;

    /**
     * @notice get current mopn token produce per block
     * @param reduceTimes mopn token produce reduce times
     */
    function currentMTPPB(
        uint256 reduceTimes
    ) public view returns (uint256 MTPPB) {
        if (reduceTimes <= MTPPBZeroTriger) {
            uint256 mapKey = reduceTimes / 500;
            if (mapKey >= MTPPBMap.length) {
                mapKey = MTPPBMap.length - 1;
            }
            MTPPB = MTPPBMap[mapKey];
            reduceTimes -= mapKey * 500;
            if (reduceTimes > 0) {
                while (true) {
                    if (reduceTimes > 17) {
                        MTPPB = (MTPPB * 997 ** 17) / (1000 ** 17);
                    } else {
                        MTPPB =
                            (MTPPB * 997 ** reduceTimes) /
                            (1000 ** reduceTimes);
                        break;
                    }
                    reduceTimes -= 17;
                }
            }
        }
    }

    /**
     * @notice settle per mopn token allocation weight mint mopn token
     */
    function settlePerMTAWMinted() public {
        if (block.number > getLastPerMTAWMintedCalcBlock()) {
            uint256 PerMTAWMinted = calcPerMTAWMinted();
            MTProduceData =
                PerMTAWMinted *
                10 ** 24 +
                block.number *
                10 ** 12 +
                getTotalMTAWs();
        }
    }

    function calcPerMTAWMinted() public view returns (uint256) {
        uint256 TotalMTAWs = getTotalMTAWs();
        uint256 PerMTAWMinted = getPerMTAWMinted();
        if (TotalMTAWs > 0) {
            uint256 LastPerMTAWMintedCalcBlock = getLastPerMTAWMintedCalcBlock();
            uint256 reduceTimes = (LastPerMTAWMintedCalcBlock -
                MTProduceStartBlock) / MTProduceReduceInterval;
            uint256 nextReduceBlock = MTProduceStartBlock +
                MTProduceReduceInterval +
                reduceTimes *
                MTProduceReduceInterval;

            while (true) {
                if (block.number > nextReduceBlock) {
                    PerMTAWMinted +=
                        ((nextReduceBlock - LastPerMTAWMintedCalcBlock) *
                            currentMTPPB(reduceTimes)) /
                        TotalMTAWs;
                    LastPerMTAWMintedCalcBlock = nextReduceBlock;
                    reduceTimes++;
                    nextReduceBlock += MTProduceReduceInterval;
                } else {
                    PerMTAWMinted +=
                        ((block.number - LastPerMTAWMintedCalcBlock) *
                            currentMTPPB(reduceTimes)) /
                        TotalMTAWs;
                    break;
                }
            }
        }
        return PerMTAWMinted;
    }

    /**
     * @notice get avatar settled unclaimed minted mopn token
     * @param avatarId avatar Id
     */
    function getAvatarSettledInboxMT(
        uint256 avatarId
    ) public view returns (uint256) {
        return AvatarMTs[avatarId] / 10 ** 52;
    }

    function getAvatarTotalMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return (AvatarMTs[avatarId] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get avatar settled per mopn token allocation weight minted mopn token number
     * @param avatarId avatar Id
     */
    function getAvatarPerMTAWMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return (AvatarMTs[avatarId] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get avatar on map mining mopn token allocation weight
     * @param avatarId avatar Id
     */
    function getAvatarMTAW(uint256 avatarId) public view returns (uint256) {
        return AvatarMTs[avatarId] % 10 ** 12;
    }

    /**
     * @notice mint avatar mopn token
     * @param avatarId avatar Id
     */
    function mintAvatarMT(uint256 avatarId) public {
        uint256 AvatarMTAW = getAvatarMTAW(avatarId);
        uint256 AvatarPerMTAWMinted = getAvatarPerMTAWMinted(avatarId);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        if (AvatarPerMTAWMinted < PerMTAWMinted && AvatarMTAW > 0) {
            uint256 amount = ((((PerMTAWMinted - AvatarPerMTAWMinted) *
                AvatarMTAW) * 90) / 100);
            AvatarMTs[avatarId] +=
                amount *
                10 ** 52 +
                (PerMTAWMinted - AvatarPerMTAWMinted) *
                10 ** 12;
            emit AvatarMTMinted(avatarId, amount);
        }
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param avatarId avatar Id
     */
    function getAvatarInboxMT(
        uint256 avatarId
    ) public view returns (uint256 inbox) {
        inbox = getAvatarSettledInboxMT(avatarId);
        uint256 PerMTAWMinted = calcPerMTAWMinted();
        uint256 AvatarPerMTAWMinted = getAvatarPerMTAWMinted(avatarId);
        uint256 AvatarMTAW = getAvatarMTAW(avatarId);

        if (AvatarPerMTAWMinted < PerMTAWMinted && AvatarMTAW > 0) {
            inbox +=
                (((PerMTAWMinted - AvatarPerMTAWMinted) * AvatarMTAW) * 90) /
                100;
        }
    }

    /**
     * @notice redeem avatar unclaimed minted mopn token
     * @param avatarId avatar Id
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    function redeemAvatarInboxMT(
        uint256 avatarId,
        IAvatar.DelegateWallet delegateWallet,
        address vault
    ) public {
        require(
            msg.sender ==
                IAvatar(avatarContract).ownerOf(
                    avatarId,
                    delegateWallet,
                    vault
                ),
            "not your avatar"
        );
        settlePerMTAWMinted();
        mintAvatarMT(avatarId);

        uint256 amount = getAvatarSettledInboxMT(avatarId);
        require(amount > 0, "empty");

        AvatarMTs[avatarId] =
            (AvatarMTs[avatarId] % (10 ** 52)) +
            amount *
            10 ** 32;
        IMOPNToken(mtContract).mint(msg.sender, amount);
        emit MTClaimed(msg.sender, amount);
    }

    /**
     * @notice batch redeem avatar unclaimed minted mopn token
     * @param avatarIds avatar Ids
     * @param delegateWallets Delegate coldwallet to specify hotwallet protocol
     * @param vaults cold wallet address
     */
    function batchRedeemAvatarInboxMT(
        uint256[] memory avatarIds,
        IAvatar.DelegateWallet[] memory delegateWallets,
        address[] memory vaults
    ) public {
        require(
            delegateWallets.length == 0 ||
                delegateWallets.length == avatarIds.length,
            "delegateWallets incorrect"
        );

        settlePerMTAWMinted();
        uint256 totalamount;
        for (uint256 i = 0; i < avatarIds.length; i++) {
            if (delegateWallets.length > 0) {
                require(
                    msg.sender ==
                        IAvatar(avatarContract).ownerOf(
                            avatarIds[i],
                            delegateWallets[i],
                            vaults[i]
                        ),
                    "not your avatar"
                );
            } else {
                require(
                    msg.sender ==
                        IAvatar(avatarContract).ownerOf(
                            avatarIds[i],
                            IAvatar.DelegateWallet.None,
                            address(0)
                        ),
                    "not your avatar"
                );
            }
            mintAvatarMT(avatarIds[i]);

            uint256 amount = getAvatarSettledInboxMT(avatarIds[i]);
            if (amount > 0) {
                AvatarMTs[avatarIds[i]] =
                    (AvatarMTs[avatarIds[i]] % (10 ** 52)) +
                    amount *
                    10 ** 32;
                totalamount += amount;
            }
        }

        IMOPNToken(mtContract).mint(msg.sender, totalamount);
        emit MTClaimed(msg.sender, totalamount);
    }

    /**
     * @notice get collection settled minted unclaimed mopn token
     * @param COID collection Id
     */
    function getCollectionSettledInboxMT(
        uint256 COID
    ) public view returns (uint256) {
        return CollectionMTs[COID] / 10 ** 52;
    }

    function getCollectionTotalMinted(
        uint256 COID
    ) public view returns (uint256) {
        return (CollectionMTs[COID] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get collection settled per mopn token allocation weight minted mopn token number
     * @param COID collection Id
     */
    function getCollectionPerMTAWMinted(
        uint256 COID
    ) public view returns (uint256) {
        return (CollectionMTs[COID] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get collection on map mining mopn token allocation weight
     * @param COID collection Id
     */
    function getCollectionMTAW(uint256 COID) public view returns (uint256) {
        return CollectionMTs[COID] % 10 ** 12;
    }

    /**
     * @notice mint collection mopn token
     * @param COID collection Id
     */
    function mintCollectionMT(uint256 COID) public {
        uint256 CollectionMTAW = getCollectionMTAW(COID);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        uint256 CollectionPerMTAWMinted = getCollectionPerMTAWMinted(COID);
        if (CollectionPerMTAWMinted < PerMTAWMinted && CollectionMTAW > 0) {
            uint256 amount = ((((PerMTAWMinted - CollectionPerMTAWMinted) *
                CollectionMTAW) * 5) / 100);
            CollectionMTs[COID] +=
                amount *
                10 ** 52 +
                (PerMTAWMinted - CollectionPerMTAWMinted) *
                10 ** 12;
            emit CollectionMTMinted(COID, amount);
        }
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param COID collection Id
     */
    function getCollectionInboxMT(
        uint256 COID
    ) public view returns (uint256 inbox) {
        inbox = getCollectionSettledInboxMT(COID);
        uint256 PerMTAWMinted = calcPerMTAWMinted();
        uint256 CollectionPerMTAWMinted = getCollectionPerMTAWMinted(COID);
        uint256 CollectionMTAW = getCollectionMTAW(COID);

        if (CollectionPerMTAWMinted < PerMTAWMinted && CollectionMTAW > 0) {
            inbox +=
                (((PerMTAWMinted - CollectionPerMTAWMinted) * CollectionMTAW) *
                    5) /
                100;
        }
    }

    /**
     * @notice redeem 1/collectionOnMapNFTNumber of collection unclaimed minted mopn token to a avatar
     * only avatar contract can calls
     * @param avatarId avatar Id
     * @param COID collection Id
     */
    function redeemCollectionInboxMT(
        uint256 avatarId,
        uint256 COID
    ) public onlyAvatar {
        uint256 amount = getCollectionSettledInboxMT(COID);
        if (amount > 0) {
            amount = amount / (getCollectionOnMapNum(COID) + 1);
            CollectionMTs[COID] -= amount * (10 ** 52);
            CollectionMTs[COID] += amount * (10 ** 32);
            AvatarMTs[avatarId] += amount * (10 ** 52);
            emit AvatarMTMinted(avatarId, amount);
        }
    }

    /**
     * @notice get Land holder settled minted unclaimed mopn token
     * @param LandId MOPN Land Id
     */
    function getLandHolderSettledInboxMT(
        uint32 LandId
    ) public view returns (uint256) {
        return LandHolderMTs[LandId] / 10 ** 52;
    }

    function getLandHolderTotalMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return (LandHolderMTs[LandId] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get Land holder settled per mopn token allocation weight minted mopn token number
     * @param LandId MOPN Land Id
     */
    function getLandHolderPerMTAWMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return (LandHolderMTs[LandId] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get Land holder on map mining mopn token allocation weight
     * @param LandId MOPN Land Id
     */
    function getLandHolderMTAW(uint32 LandId) public view returns (uint256) {
        return LandHolderMTs[LandId] % 10 ** 12;
    }

    /**
     * @notice mint Land holder mopn token
     * @param LandId MOPN Land Id
     */
    function mintLandHolderMT(uint32 LandId) public {
        uint256 LandHolderMTAW = getLandHolderMTAW(LandId);
        uint256 PerMTAWMinted = getPerMTAWMinted();
        uint256 LandHolderPerMTAWMinted = getLandHolderPerMTAWMinted(LandId);
        if (LandHolderPerMTAWMinted < PerMTAWMinted && LandHolderMTAW > 0) {
            LandHolderMTs[LandId] +=
                ((((PerMTAWMinted - LandHolderPerMTAWMinted) * LandHolderMTAW) *
                    5) / 100) *
                10 ** 52 +
                (PerMTAWMinted - LandHolderPerMTAWMinted) *
                10 ** 12;
        }
    }

    /**
     * @notice get Land holder realtime unclaimed minted mopn token
     * @param LandId MOPN Land Id
     */
    function getLandHolderInboxMT(
        uint32 LandId
    ) public view returns (uint256 inbox) {
        inbox = getLandHolderSettledInboxMT(LandId);
        uint256 PerMTAWMinted = calcPerMTAWMinted();
        uint256 LandHolderPerMTAWMinted = getLandHolderPerMTAWMinted(LandId);
        uint256 LandHolderMTAW = getLandHolderMTAW(LandId);

        if (LandHolderPerMTAWMinted < PerMTAWMinted && LandHolderMTAW > 0) {
            inbox +=
                (((PerMTAWMinted - LandHolderPerMTAWMinted) * LandHolderMTAW) *
                    5) /
                100;
        }
    }

    /**
     * @notice redeem Land holder unclaimed minted mopn token
     * @param LandId MOPN Land Id
     */
    function redeemLandHolderInboxMT(uint32 LandId) public {
        require(
            msg.sender == IERC721(landContract).ownerOf(LandId),
            "not your Land"
        );
        settlePerMTAWMinted();
        mintLandHolderMT(LandId);

        uint256 amount = getLandHolderSettledInboxMT(LandId);
        require(amount > 0, "empty");

        LandHolderMTs[LandId] =
            (LandHolderMTs[LandId] % (10 ** 52)) +
            amount *
            10 ** 32;

        IMOPNToken(mtContract).mint(msg.sender, amount);
    }

    function getLandHolderRedeemed(
        uint32 LandId
    ) public view returns (uint256) {
        return getLandHolderTotalMinted(LandId) + getLandHolderInboxMT(LandId);
    }

    bool public whiteListRequire;

    function setWhiteListRequire(bool whiteListRequire_) public onlyOwner {
        whiteListRequire = whiteListRequire_;
    }

    bytes32 public whiteListRoot;

    // Collection Id
    uint256 COIDCounter;

    mapping(uint256 => address) public COIDMap;

    /**
     * @notice record the collection's COID and number of collection nfts which is standing on the map with last 6 digit
     *
     * Collection address => COID * 1000000 + on map nft number
     */
    mapping(address => uint256) public collectionMap;

    /**
     * @notice use collection Id to get collection contract address
     * @param COID collection Id
     * @return contractAddress collection contract address
     */
    function getCollectionContract(uint256 COID) public view returns (address) {
        return COIDMap[COID];
    }

    /**
     * @notice use collection contract address to get collection Id
     * @param collectionContract collection contract address
     * @return COID collection Id
     */
    function getCollectionCOID(
        address collectionContract
    ) public view returns (uint256) {
        return collectionMap[collectionContract] / 10 ** 16;
    }

    /**
     * @notice batch call for {getCollectionCOID}
     * @param collectionContracts multi collection contracts
     */
    function getCollectionsCOIDs(
        address[] memory collectionContracts
    ) public view returns (uint256[] memory COIDs) {
        COIDs = new uint256[](collectionContracts.length);
        for (uint256 i = 0; i < collectionContracts.length; i++) {
            COIDs[i] = collectionMap[collectionContracts[i]] / 10 ** 16;
        }
    }

    /**
     * Generate a collection id for new collection
     * @param collectionContract collection contract adddress
     * @param proofs collection whitelist proofs
     */
    function generateCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) public returns (uint256 COID) {
        COID = getCollectionCOID(collectionContract);
        if (COID == 0) {
            if (whiteListRequire) {
                require(
                    isInWhiteList(collectionContract, proofs),
                    "not in whitelist"
                );
            } else {
                require(
                    IERC165(collectionContract).supportsInterface(
                        type(IERC721).interfaceId
                    ),
                    "not a erc721 compatible nft"
                );
            }

            COIDCounter++;
            COIDMap[COIDCounter] = collectionContract;
            collectionMap[collectionContract] =
                COIDCounter *
                10 ** 16 +
                1000000;
            COID = COIDCounter;
        } else {
            addCollectionAvatarNum(COID);
        }
    }

    /**
     * @notice check if this collection is in white list
     * @param collectionContract collection contract address
     * @param proofs collection whitelist proofs
     */
    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                proofs,
                whiteListRoot,
                keccak256(
                    bytes.concat(keccak256(abi.encode(collectionContract)))
                )
            );
    }

    /**
     * @notice update whitelist root
     * @param whiteListRoot_ white list merkle tree root
     */
    function updateWhiteList(bytes32 whiteListRoot_) public onlyOwner {
        whiteListRoot = whiteListRoot_;
    }

    /**
     * @notice get NFT collection On map avatar number
     * @param COID collection Id
     */
    function getCollectionOnMapNum(uint256 COID) public view returns (uint256) {
        return collectionMap[getCollectionContract(COID)] % 1000000;
    }

    function addCollectionOnMapNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)]++;
    }

    function subCollectionOnMapNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)]--;
    }

    /**
     * @notice get NFT collection minted avatar number
     * @param COID collection Id
     */
    function getCollectionAvatarNum(
        uint256 COID
    ) public view returns (uint256) {
        return
            (collectionMap[getCollectionContract(COID)] % 10 ** 16) / 1000000;
    }

    function addCollectionAvatarNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)] += 1000000;
    }

    function getCollectionInfo(
        uint256 COID
    )
        public
        view
        returns (
            address collectionAddress,
            uint256 onMapNum,
            uint256 avatarNum,
            uint256 totalMTAWs,
            uint256 totalMinted
        )
    {
        collectionAddress = getCollectionContract(COID);
        onMapNum = getCollectionOnMapNum(COID);
        avatarNum = getCollectionAvatarNum(COID);
        totalMTAWs = getCollectionMTAW(COID);
        totalMinted =
            getCollectionTotalMinted(COID) +
            getCollectionInboxMT(COID);
    }

    address public auctionHouseContract;
    address public avatarContract;
    address public bombContract;
    address public mtContract;
    address public mapContract;
    address public landContract;

    function updateMOPNContracts(
        address auctionHouseContract_,
        address avatarContract_,
        address bombContract_,
        address mtContract_,
        address mapContract_,
        address landContract_
    ) public onlyOwner {
        auctionHouseContract = auctionHouseContract_;
        avatarContract = avatarContract_;
        bombContract = bombContract_;
        mtContract = mtContract_;
        mapContract = mapContract_;
        landContract = landContract_;
    }

    // Bomb
    function mintBomb(address to, uint256 amount) public onlyAuctionHouse {
        IBomb(bombContract).mint(to, 1, amount);
    }

    function burnBomb(
        address from,
        uint256 amount,
        uint256 avatarId,
        uint256 COID,
        uint32 LandId
    ) public onlyAvatar {
        if (avatarId > 0 && COID > 0 && LandId > 0) {
            _addMTAW(avatarId, COID, LandId, 1);
        }
        IBomb(bombContract).burn(from, 1, amount);
    }

    // Land
    function mintLand(address to) public onlyAuctionHouse {
        ILand(landContract).auctionMint(to, 1);
    }

    function redeemAgio() public {
        IAuctionHouse(auctionHouseContract).redeemAgioTo(msg.sender);
    }

    ///todo remove before prod
    function giveupOwnership() public onlyOwner {
        IBomb(bombContract).transferOwnership(owner());
        IMOPNToken(mtContract).transferOwnership(owner());
    }

    function _addMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) internal {
        settlePerMTAWMinted();
        MTProduceData += amount;
        mintAvatarMT(avatarId);
        AvatarMTs[avatarId] += amount;
        mintCollectionMT(COID);
        CollectionMTs[COID] += amount;
        mintLandHolderMT(LandId);
        LandHolderMTs[LandId] += amount;
    }

    function _subMTAW(uint256 avatarId, uint256 COID, uint32 LandId) internal {
        settlePerMTAWMinted();
        uint256 amount = getAvatarMTAW(avatarId);
        MTProduceData -= amount;
        mintAvatarMT(avatarId);
        AvatarMTs[avatarId] -= amount;
        mintCollectionMT(COID);
        CollectionMTs[COID] -= amount;
        mintLandHolderMT(LandId);
        LandHolderMTs[LandId] -= amount;
    }

    modifier onlyAuctionHouse() {
        require(msg.sender == auctionHouseContract, "not allowed");
        _;
    }

    modifier onlyAvatar() {
        require(msg.sender == avatarContract, "not allowed");
        _;
    }

    modifier onlyMap() {
        require(msg.sender == mapContract, "not allowed");
        _;
    }
}
