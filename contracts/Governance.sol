// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
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

    /// @notice PerEAWMinted * 10 ** 24 + EnergyLastMintedBlock * 10 ** 12 + TotalEAWs
    uint256 public EnergyProduceData;

    mapping(uint256 => uint256) public AvatarEnergys;

    mapping(uint256 => uint256) public CollectionEnergys;

    mapping(uint32 => uint256) public PassHolderEnergys;

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
     * @param PassId mopn pass Id
     * @param amount EAW amount
     */
    function addEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId,
        uint256 amount
    ) public onlyMap {
        _addEAW(avatarId, COID, PassId, amount);
    }

    /**
     * substruct on map mining energy allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param PassId mopn pass Id
     */
    function subEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId
    ) public onlyMap {
        _subEAW(avatarId, COID, PassId);
    }

    /**
     * @notice get current energy produce per block
     * @param reduceTimes energy produce reduce times
     */
    function currentEPPB(
        uint256 reduceTimes
    ) public pure returns (uint256 EPPB) {
        EPPB = EnergyProducePerBlock;
        while (true) {
            if (reduceTimes > 17) {
                EPPB = (EnergyProducePerBlock * 997 ** 17) / (1000 ** 17);
            } else {
                EPPB =
                    (EnergyProducePerBlock * 997 ** reduceTimes) /
                    (1000 ** reduceTimes);
                break;
            }
            reduceTimes -= 17;
        }
    }

    /**
     * @notice settle per energy allocation weight mint energy
     */
    function settlePerEAWEnergy() public {
        uint256 EnergyLastMintedBlock = getEnergyLastMintedBlock();

        if (block.number > EnergyLastMintedBlock) {
            uint256 TotalEAWs = getTotalEAWs();
            uint256 PerEAWMinted = getPerEAWMinted();
            if (TotalEAWs > 0) {
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
            EnergyProduceData =
                PerEAWMinted *
                10 ** 24 +
                block.number *
                10 ** 12 +
                TotalEAWs;
        }
    }

    /**
     * @notice get avatar settled unclaimed minted energy
     * @param avatarId avatar Id
     */
    function getAvatarSettledInboxEnergy(
        uint256 avatarId
    ) public view returns (uint256) {
        return AvatarEnergys[avatarId] / 10 ** 50;
    }

    /**
     * @notice get avatar settled per energy allocation weight minted energy number
     * @param avatarId avatar Id
     */
    function getAvatarPerEAWMinted(
        uint256 avatarId
    ) public view returns (uint256) {
        return (AvatarEnergys[avatarId] % 10 ** 50) / 10 ** 25;
    }

    /**
     * @notice get avatar on map mining energy allocation weight
     * @param avatarId avatar Id
     */
    function getAvatarEAW(uint256 avatarId) public view returns (uint256) {
        return AvatarEnergys[avatarId] % 10 ** 25;
    }

    /**
     * @notice mint avatar energy
     * @param avatarId avatar Id
     */
    function mintAvatarEnergy(uint256 avatarId) public {
        uint256 AvatarPerEAWMinted = getAvatarPerEAWMinted(avatarId);
        uint256 PerEAWMinted = getPerEAWMinted();
        if (AvatarPerEAWMinted < PerEAWMinted) {
            uint256 AvatarEAW = getAvatarEAW(avatarId);
            uint256 AvatarEnergyInbox = getAvatarSettledInboxEnergy(avatarId);
            if (AvatarEAW > 0) {
                AvatarEnergyInbox += ((((PerEAWMinted - AvatarPerEAWMinted) *
                    AvatarEAW) * 90) / 100);
            }

            AvatarEnergys[avatarId] =
                AvatarEnergyInbox *
                10 ** 50 +
                PerEAWMinted *
                10 ** 25 +
                AvatarEAW;
        }
    }

    /**
     * @notice get avatar realtime unclaimed minted energy
     * @param avatarId avatar Id
     */
    function getAvatarInboxEnergy(
        uint256 avatarId
    ) public view returns (uint256 inbox) {
        uint256 PerEAWMinted = getPerEAWMinted();
        inbox = getAvatarSettledInboxEnergy(avatarId);
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

        AvatarEnergys[avatarId] = AvatarEnergys[avatarId] % (10 ** 50);
        IEnergy(energyContract).mint(msg.sender, amount);
    }

    /**
     * @notice get collection settled minted unclaimed energy
     * @param COID collection Id
     */
    function getCollectionSettledInboxEnergy(
        uint256 COID
    ) public view returns (uint256) {
        return CollectionEnergys[COID] / 10 ** 50;
    }

    /**
     * @notice get collection settled per energy allocation weight minted energy number
     * @param COID collection Id
     */
    function getCollectionPerEAWMinted(
        uint256 COID
    ) public view returns (uint256) {
        return (CollectionEnergys[COID] % 10 ** 50) / 10 ** 25;
    }

    /**
     * @notice get collection on map mining energy allocation weight
     * @param COID collection Id
     */
    function getCollectionEAW(uint256 COID) public view returns (uint256) {
        return CollectionEnergys[COID] % 10 ** 25;
    }

    /**
     * @notice mint collection energy
     * @param COID collection Id
     */
    function mintCollectionEnergy(uint256 COID) public {
        uint256 PerEAWMinted = getPerEAWMinted();
        uint256 CollectionPerEAWMinted = getCollectionPerEAWMinted(COID);
        if (CollectionPerEAWMinted < PerEAWMinted) {
            uint256 CollectionEAW = getCollectionEAW(COID);
            uint256 CollectionEnergyInbox = getCollectionSettledInboxEnergy(
                COID
            );
            if (CollectionEAW > 0) {
                CollectionEnergyInbox += ((((PerEAWMinted -
                    CollectionPerEAWMinted) * CollectionEAW) * 9) / 100);
            }
            CollectionEnergys[COID] =
                CollectionEnergyInbox *
                10 ** 50 +
                PerEAWMinted *
                10 ** 25 +
                CollectionEAW;
        }
    }

    /**
     * @notice get collection realtime unclaimed minted energy
     * @param COID collection Id
     */
    function getCollectionInboxEnergy(
        uint256 COID
    ) public view returns (uint256 inbox) {
        uint256 PerEAWMinted = getPerEAWMinted();
        inbox = getCollectionSettledInboxEnergy(COID);
        uint256 CollectionPerEAWMinted = getCollectionPerEAWMinted(COID);
        uint256 CollectionEAW = getCollectionEAW(COID);

        if (CollectionPerEAWMinted < PerEAWMinted && CollectionEAW > 0) {
            inbox +=
                (((PerEAWMinted - CollectionPerEAWMinted) * CollectionEAW) *
                    9) /
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
            CollectionEnergys[COID] -= amount * (10 ** 50);
            AvatarEnergys[avatarId] += amount * (10 ** 50);
        }
    }

    /**
     * @notice get pass holder settled minted unclaimed energy
     * @param PassId MOPN Pass Id
     */
    function getPassHolderSettledInboxEnergy(
        uint32 PassId
    ) public view returns (uint256) {
        return PassHolderEnergys[PassId] / 10 ** 50;
    }

    /**
     * @notice get Pass holder settled per energy allocation weight minted energy number
     * @param PassId MOPN Pass Id
     */
    function getPassHolderPerEAWMinted(
        uint32 PassId
    ) public view returns (uint256) {
        return (PassHolderEnergys[PassId] % 10 ** 50) / 10 ** 25;
    }

    /**
     * @notice get Pass holder on map mining energy allocation weight
     * @param PassId MOPN Pass Id
     */
    function getPassHolderEAW(uint32 PassId) public view returns (uint256) {
        return PassHolderEnergys[PassId] % 10 ** 25;
    }

    /**
     * @notice mint Pass holder energy
     * @param PassId MOPN Pass Id
     */
    function mintPassHolderEnergy(uint32 PassId) public {
        uint256 PerEAWMinted = getPerEAWMinted();
        uint256 PassHolderPerEAWMinted = getPassHolderPerEAWMinted(PassId);
        if (PassHolderPerEAWMinted < PerEAWMinted) {
            uint256 PassHolderEAW = getPassHolderEAW(PassId);
            uint256 PassHolderEnergyInbox = getPassHolderSettledInboxEnergy(
                PassId
            );
            if (PassHolderEAW > 0) {
                PassHolderEnergyInbox +=
                    ((PerEAWMinted - PassHolderPerEAWMinted) * PassHolderEAW) /
                    100;
            }
            PassHolderEnergys[PassId] =
                PassHolderEnergyInbox *
                10 ** 50 +
                PerEAWMinted *
                10 ** 25 +
                PassHolderEAW;
        }
    }

    /**
     * @notice get Pass holder realtime unclaimed minted energy
     * @param PassId MOPN Pass Id
     */
    function getPassHolderInboxEnergy(
        uint32 PassId
    ) public view returns (uint256 inbox) {
        uint256 PerEAWMinted = getPerEAWMinted();
        inbox = getPassHolderSettledInboxEnergy(PassId);
        uint256 PassHolderPerEAWMinted = getPassHolderPerEAWMinted(PassId);
        uint256 PassHolderEAW = getPassHolderEAW(PassId);

        if (PassHolderPerEAWMinted < PerEAWMinted && PassHolderEAW > 0) {
            inbox +=
                ((PerEAWMinted - PassHolderPerEAWMinted) * PassHolderEAW) /
                100;
        }
    }

    /**
     * @notice redeem Pass holder unclaimed minted energy
     * @param PassId MOPN Pass Id
     */
    function redeemPassHolderInboxEnergy(uint32 PassId) public onlyAvatar {
        require(
            msg.sender == IERC721(passContract).ownerOf(PassId),
            "not your pass"
        );
        settlePerEAWEnergy();
        mintPassHolderEnergy(PassId);

        uint256 amount = getPassHolderSettledInboxEnergy(PassId);
        require(amount > 0, "empty");

        PassHolderEnergys[PassId] = PassHolderEnergys[PassId] % (10 ** 50);
        IEnergy(energyContract).mint(msg.sender, amount);
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

    address public arsenalContract;

    function updateArsenalContract(address arsenalContract_) public onlyOwner {
        arsenalContract = arsenalContract_;
    }

    address public avatarContract;

    function updateAvatarContract(address avatarContract_) public onlyOwner {
        avatarContract = avatarContract_;
    }

    address public bombContract;

    function updateBombContract(address bombContract_) public onlyOwner {
        bombContract = bombContract_;
    }

    address public energyContract;

    function updateEnergyContract(address energyContract_) public onlyOwner {
        energyContract = energyContract_;
    }

    address public mapContract;

    function updateMapContract(address mapContract_) public onlyOwner {
        mapContract = mapContract_;
    }

    address public passContract;

    function updatePassContract(address passContract_) public onlyOwner {
        passContract = passContract_;
    }

    // Bomb
    function mintBomb(address to, uint256 amount) public onlyArsenal {
        IBomb(bombContract).mint(to, 1, amount);
    }

    function burnBomb(
        address from,
        uint256 amount,
        uint256 avatarId,
        uint256 COID,
        uint32 PassId
    ) public onlyAvatar {
        if (avatarId > 0 && COID > 0 && PassId > 0) {
            _addEAW(avatarId, COID, PassId, 1);
        }
        IBomb(bombContract).burn(from, 1, amount);
    }

    function _addEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId,
        uint256 amount
    ) internal {
        settlePerEAWEnergy();
        EnergyProduceData += amount;
        mintAvatarEnergy(avatarId);
        AvatarEnergys[avatarId] += amount;
        mintCollectionEnergy(COID);
        CollectionEnergys[COID] += amount;
        mintPassHolderEnergy(PassId);
        PassHolderEnergys[PassId] += amount;
    }

    function _subEAW(uint256 avatarId, uint256 COID, uint32 PassId) internal {
        settlePerEAWEnergy();
        uint256 amount = getAvatarEAW(avatarId);
        EnergyProduceData -= amount;
        mintAvatarEnergy(avatarId);
        AvatarEnergys[avatarId] -= amount;
        mintCollectionEnergy(COID);
        CollectionEnergys[COID] -= amount;
        mintPassHolderEnergy(PassId);
        PassHolderEnergys[PassId] -= amount;
    }

    modifier onlyArsenal() {
        require(msg.sender == arsenalContract, "not allowed");
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
