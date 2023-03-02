// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IAvatar.sol";
import "./interfaces/IAuctionHouse.sol";
import "./interfaces/IEnergy.sol";
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
    uint256 public constant EnergyProducePerBlock = 600000000000;

    uint256 public constant EnergyProduceReduceInterval = 50000;

    uint256 public EnergyProduceStartBlock;

    /// @notice PerEAWMintedEnergy * 10 ** 24 + EnergyLastMintedBlock * 10 ** 12 + TotalEAWs
    uint256 public EnergyProduceData;

    // @notice Energy Inbox * 10 ** 52 + Total Minted Energy * 10 ** 32 + PerEAWMintedEnergy * 10 ** 12 + TotalEAWs
    mapping(uint256 => uint256) public AvatarEnergys;

    mapping(uint256 => uint256) public CollectionEnergys;

    mapping(uint32 => uint256) public LandHolderEnergys;

    constructor(uint256 EnergyProduceStartBlock_, bool whiteListRequire_) {
        EnergyProduceStartBlock = EnergyProduceStartBlock_;
        whiteListRequire = whiteListRequire_;
    }

    /**
     * @notice get settled Per Energy Allocation Weight minted energy number
     */
    function getPerEAWMinted() public view returns (uint256) {
        return EnergyProduceData / 10 ** 24;
    }

    /**
     * @notice get Energy last minted settlement block number
     */
    function getEnergyLastMintedBlock() public view returns (uint256) {
        return (EnergyProduceData % 10 ** 24) / 10 ** 12;
    }

    /**
     * @notice get total energy allocation weights
     */
    function getTotalEAWs() public view returns (uint256) {
        return EnergyProduceData % 10 ** 12;
    }

    /**
     * add on map mining energy allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId mopn Land Id
     * @param amount EAW amount
     */
    function addEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) public onlyMap {
        _addEAW(avatarId, COID, LandId, amount);
    }

    /**
     * substruct on map mining energy allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId mopn Land Id
     */
    function subEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId
    ) public onlyMap {
        _subEAW(avatarId, COID, LandId);
    }

    uint256[] EPPBMap = [
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

    uint256 EPPBZeroTriger = 8211;

    /**
     * @notice get current energy produce per block
     * @param reduceTimes energy produce reduce times
     */
    function currentEPPB(
        uint256 reduceTimes
    ) public view returns (uint256 EPPB) {
        if (reduceTimes <= EPPBZeroTriger) {
            uint256 mapKey = reduceTimes / 500;
            if (mapKey >= EPPBMap.length) {
                mapKey = EPPBMap.length - 1;
            }
            EPPB = EPPBMap[mapKey];
            reduceTimes -= mapKey * 500;
            if (reduceTimes > 0) {
                while (true) {
                    if (reduceTimes > 17) {
                        EPPB = (EPPB * 997 ** 17) / (1000 ** 17);
                    } else {
                        EPPB =
                            (EPPB * 997 ** reduceTimes) /
                            (1000 ** reduceTimes);
                        break;
                    }
                    reduceTimes -= 17;
                }
            }
        }
    }

    /**
     * @notice settle per energy allocation weight mint energy
     */
    function settlePerEAWEnergy() public {
        if (block.number > getEnergyLastMintedBlock()) {
            uint256 PerEAWMinted = calcPerEAWEnergy();
            EnergyProduceData =
                PerEAWMinted *
                10 ** 24 +
                block.number *
                10 ** 12 +
                getTotalEAWs();
        }
    }

    function calcPerEAWEnergy() public view returns (uint256) {
        uint256 TotalEAWs = getTotalEAWs();
        uint256 PerEAWMinted = getPerEAWMinted();
        if (TotalEAWs > 0) {
            uint256 EnergyLastMintedBlock = getEnergyLastMintedBlock();
            uint256 reduceTimes = (EnergyLastMintedBlock -
                EnergyProduceStartBlock) / EnergyProduceReduceInterval;
            uint256 nextReduceBlock = EnergyProduceStartBlock +
                EnergyProduceReduceInterval +
                reduceTimes *
                EnergyProduceReduceInterval;

            while (true) {
                if (block.number > nextReduceBlock) {
                    PerEAWMinted +=
                        ((nextReduceBlock - EnergyLastMintedBlock) *
                            currentEPPB(reduceTimes)) /
                        TotalEAWs;
                    EnergyLastMintedBlock = nextReduceBlock;
                    reduceTimes++;
                    nextReduceBlock += EnergyProduceReduceInterval;
                } else {
                    PerEAWMinted +=
                        ((block.number - EnergyLastMintedBlock) *
                            currentEPPB(reduceTimes)) /
                        TotalEAWs;
                    break;
                }
            }
        }
        return PerEAWMinted;
    }

    /**
     * @notice get avatar settled unclaimed minted energy
     * @param avatarId avatar Id
     */
    function getAvatarSettledInboxEnergy(
        uint256 avatarId
    ) public view returns (uint256) {
        return AvatarEnergys[avatarId] / 10 ** 52;
    }

    function getAvatarTotalMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return (AvatarEnergys[avatarId] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get avatar settled per energy allocation weight minted energy number
     * @param avatarId avatar Id
     */
    function getAvatarPerEAWMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return (AvatarEnergys[avatarId] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get avatar on map mining energy allocation weight
     * @param avatarId avatar Id
     */
    function getAvatarEAW(uint256 avatarId) public view returns (uint256) {
        return AvatarEnergys[avatarId] % 10 ** 12;
    }

    /**
     * @notice mint avatar energy
     * @param avatarId avatar Id
     */
    function mintAvatarEnergy(uint256 avatarId) public {
        uint256 AvatarEAW = getAvatarEAW(avatarId);
        uint256 AvatarPerEAWMinted = getAvatarPerEAWMinted(avatarId);
        uint256 PerEAWMinted = getPerEAWMinted();
        if (AvatarPerEAWMinted < PerEAWMinted && AvatarEAW > 0) {
            AvatarEnergys[avatarId] +=
                ((((PerEAWMinted - AvatarPerEAWMinted) * AvatarEAW) * 90) /
                    100) *
                10 ** 52 +
                (PerEAWMinted - AvatarPerEAWMinted) *
                10 ** 12;
        }
    }

    /**
     * @notice get avatar realtime unclaimed minted energy
     * @param avatarId avatar Id
     */
    function getAvatarInboxEnergy(
        uint256 avatarId
    ) public view returns (uint256 inbox) {
        inbox = getAvatarSettledInboxEnergy(avatarId);
        uint256 PerEAWMinted = calcPerEAWEnergy();
        uint256 AvatarPerEAWMinted = getAvatarPerEAWMinted(avatarId);
        uint256 AvatarEAW = getAvatarEAW(avatarId);

        if (AvatarPerEAWMinted < PerEAWMinted && AvatarEAW > 0) {
            inbox +=
                (((PerEAWMinted - AvatarPerEAWMinted) * AvatarEAW) * 90) /
                100;
        }
    }

    /**
     * @notice redeem avatar unclaimed minted energy
     * @param avatarId avatar Id
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    function redeemAvatarInboxEnergy(
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
        settlePerEAWEnergy();
        mintAvatarEnergy(avatarId);

        uint256 amount = getAvatarSettledInboxEnergy(avatarId);
        require(amount > 0, "empty");

        AvatarEnergys[avatarId] =
            (AvatarEnergys[avatarId] % (10 ** 52)) +
            amount *
            10 ** 32;
        IEnergy(energyContract).mint(msg.sender, amount);
    }

    /**
     * @notice get collection settled minted unclaimed energy
     * @param COID collection Id
     */
    function getCollectionSettledInboxEnergy(
        uint256 COID
    ) public view returns (uint256) {
        return CollectionEnergys[COID] / 10 ** 52;
    }

    function getCollectionTotalMinted(
        uint256 COID
    ) public view returns (uint256) {
        return (CollectionEnergys[COID] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get collection settled per energy allocation weight minted energy number
     * @param COID collection Id
     */
    function getCollectionPerEAWMinted(
        uint256 COID
    ) public view returns (uint256) {
        return (CollectionEnergys[COID] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get collection on map mining energy allocation weight
     * @param COID collection Id
     */
    function getCollectionEAW(uint256 COID) public view returns (uint256) {
        return CollectionEnergys[COID] % 10 ** 12;
    }

    /**
     * @notice mint collection energy
     * @param COID collection Id
     */
    function mintCollectionEnergy(uint256 COID) public {
        uint256 CollectionEAW = getCollectionEAW(COID);
        uint256 PerEAWMinted = getPerEAWMinted();
        uint256 CollectionPerEAWMinted = getCollectionPerEAWMinted(COID);
        if (CollectionPerEAWMinted < PerEAWMinted && CollectionEAW > 0) {
            CollectionEnergys[COID] +=
                ((((PerEAWMinted - CollectionPerEAWMinted) * CollectionEAW) *
                    5) / 100) *
                10 ** 52 +
                (PerEAWMinted - CollectionPerEAWMinted) *
                10 ** 12;
        }
    }

    /**
     * @notice get collection realtime unclaimed minted energy
     * @param COID collection Id
     */
    function getCollectionInboxEnergy(
        uint256 COID
    ) public view returns (uint256 inbox) {
        inbox = getCollectionSettledInboxEnergy(COID);
        uint256 PerEAWMinted = calcPerEAWEnergy();
        uint256 CollectionPerEAWMinted = getCollectionPerEAWMinted(COID);
        uint256 CollectionEAW = getCollectionEAW(COID);

        if (CollectionPerEAWMinted < PerEAWMinted && CollectionEAW > 0) {
            inbox +=
                (((PerEAWMinted - CollectionPerEAWMinted) * CollectionEAW) *
                    5) /
                100;
        }
    }

    /**
     * @notice redeem 1/collectionOnMapNFTNumber of collection unclaimed minted energy to a avatar
     * only avatar contract can calls
     * @param avatarId avatar Id
     * @param COID collection Id
     */
    function redeemCollectionInboxEnergy(
        uint256 avatarId,
        uint256 COID
    ) public onlyAvatar {
        uint256 amount = getCollectionSettledInboxEnergy(COID);
        if (amount > 0) {
            amount = amount / (getCollectionOnMapNum(COID) + 1);
            CollectionEnergys[COID] -= amount * (10 ** 52);
            CollectionEnergys[COID] += amount * (10 ** 32);
            AvatarEnergys[avatarId] += amount * (10 ** 52);
        }
    }

    /**
     * @notice get Land holder settled minted unclaimed energy
     * @param LandId MOPN Land Id
     */
    function getLandHolderSettledInboxEnergy(
        uint32 LandId
    ) public view returns (uint256) {
        return LandHolderEnergys[LandId] / 10 ** 52;
    }

    function getLandHolderTotalMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return (LandHolderEnergys[LandId] % 10 ** 52) / 10 ** 32;
    }

    /**
     * @notice get Land holder settled per energy allocation weight minted energy number
     * @param LandId MOPN Land Id
     */
    function getLandHolderPerEAWMinted(
        uint32 LandId
    ) public view returns (uint256) {
        return (LandHolderEnergys[LandId] % 10 ** 32) / 10 ** 12;
    }

    /**
     * @notice get Land holder on map mining energy allocation weight
     * @param LandId MOPN Land Id
     */
    function getLandHolderEAW(uint32 LandId) public view returns (uint256) {
        return LandHolderEnergys[LandId] % 10 ** 12;
    }

    /**
     * @notice mint Land holder energy
     * @param LandId MOPN Land Id
     */
    function mintLandHolderEnergy(uint32 LandId) public {
        uint256 LandHolderEAW = getLandHolderEAW(LandId);
        uint256 PerEAWMinted = getPerEAWMinted();
        uint256 LandHolderPerEAWMinted = getLandHolderPerEAWMinted(LandId);
        if (LandHolderPerEAWMinted < PerEAWMinted && LandHolderEAW > 0) {
            LandHolderEnergys[LandId] +=
                ((((PerEAWMinted - LandHolderPerEAWMinted) * LandHolderEAW) *
                    5) / 100) *
                10 ** 52 +
                (PerEAWMinted - LandHolderPerEAWMinted) *
                10 ** 12;
        }
    }

    /**
     * @notice get Land holder realtime unclaimed minted energy
     * @param LandId MOPN Land Id
     */
    function getLandHolderInboxEnergy(
        uint32 LandId
    ) public view returns (uint256 inbox) {
        inbox = getLandHolderSettledInboxEnergy(LandId);
        uint256 PerEAWMinted = calcPerEAWEnergy();
        uint256 LandHolderPerEAWMinted = getLandHolderPerEAWMinted(LandId);
        uint256 LandHolderEAW = getLandHolderEAW(LandId);

        if (LandHolderPerEAWMinted < PerEAWMinted && LandHolderEAW > 0) {
            inbox +=
                (((PerEAWMinted - LandHolderPerEAWMinted) * LandHolderEAW) *
                    5) /
                100;
        }
    }

    /**
     * @notice redeem Land holder unclaimed minted energy
     * @param LandId MOPN Land Id
     */
    function redeemLandHolderInboxEnergy(uint32 LandId) public onlyAvatar {
        require(
            msg.sender == IERC721(landContract).ownerOf(LandId),
            "not your Land"
        );
        settlePerEAWEnergy();
        mintLandHolderEnergy(LandId);

        uint256 amount = getLandHolderSettledInboxEnergy(LandId);
        require(amount > 0, "empty");

        LandHolderEnergys[LandId] =
            (LandHolderEnergys[LandId] % (10 ** 52)) +
            amount *
            10 ** 32;

        IEnergy(energyContract).mint(msg.sender, amount);
    }

    function getLandHolderRedeemed(
        uint32 LandId
    ) public view returns (uint256) {
        return
            getLandHolderTotalMinted(LandId) + getLandHolderInboxEnergy(LandId);
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
            uint256 totalEAWs,
            uint256 totalMinted
        )
    {
        collectionAddress = getCollectionContract(COID);
        onMapNum = getCollectionOnMapNum(COID);
        avatarNum = getCollectionAvatarNum(COID);
        totalEAWs = getCollectionEAW(COID);
        totalMinted =
            getCollectionTotalMinted(COID) +
            getCollectionInboxEnergy(COID);
    }

    address public auctionHouseContract;
    address public avatarContract;
    address public bombContract;
    address public energyContract;
    address public mapContract;
    address public landContract;

    function updateMOPNContracts(
        address auctionHouseContract_,
        address avatarContract_,
        address bombContract_,
        address energyContract_,
        address mapContract_,
        address landContract_
    ) public onlyOwner {
        auctionHouseContract = auctionHouseContract_;
        avatarContract = avatarContract_;
        bombContract = bombContract_;
        energyContract = energyContract_;
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
            _addEAW(avatarId, COID, LandId, 1);
        }
        IBomb(bombContract).burn(from, 1, amount);
    }

    // Land
    function mintLand(address to) public onlyAuctionHouse {
        ILand(landContract).safeMint(to);
    }

    function redeemAgio() public {
        IAuctionHouse(auctionHouseContract).redeemAgioTo(msg.sender);
    }

    function _addEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) internal {
        settlePerEAWEnergy();
        EnergyProduceData += amount;
        mintAvatarEnergy(avatarId);
        AvatarEnergys[avatarId] += amount;
        mintCollectionEnergy(COID);
        CollectionEnergys[COID] += amount;
        mintLandHolderEnergy(LandId);
        LandHolderEnergys[LandId] += amount;
    }

    function _subEAW(uint256 avatarId, uint256 COID, uint32 LandId) internal {
        settlePerEAWEnergy();
        uint256 amount = getAvatarEAW(avatarId);
        EnergyProduceData -= amount;
        mintAvatarEnergy(avatarId);
        AvatarEnergys[avatarId] -= amount;
        mintCollectionEnergy(COID);
        CollectionEnergys[COID] -= amount;
        mintLandHolderEnergy(LandId);
        LandHolderEnergys[LandId] -= amount;
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
