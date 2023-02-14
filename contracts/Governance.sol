// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract Governance is Multicall, Ownable {
    uint256 constant EnergyProducePerBlock = 600000000000;

    uint256 constant EnergyProduceReduceInterval = 50000;

    uint256 EnergyProduceStartBlock;

    // PerEAWMinted * 10 ** 24 + EnergyLastMintedBlock * 10 ** 12 + TotalEAWs
    uint256 EnergyProduceData;

    mapping(uint256 => uint256) public AvatarEnergys;

    mapping(uint256 => uint256) public CollectionEnergys;

    mapping(uint32 => uint256) public PassHolderEnergys;

    constructor(uint256 EnergyProduceStartBlock_) {
        EnergyProduceStartBlock = EnergyProduceStartBlock_;
    }

    function getPerEAWMinted() public view returns (uint256) {
        return EnergyProduceData / 10 ** 24;
    }

    function getEnergyLastMintedBlock() public view returns (uint256) {
        return (EnergyProduceData % 10 ** 24) / 10 ** 12;
    }

    function getTotalEAWs() public view returns (uint256) {
        return EnergyProduceData % 10 ** 12;
    }

    function addEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId,
        uint256 amount
    ) public onlyMap {
        _addEAW(avatarId, COID, PassId, amount);
    }

    function _addEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId,
        uint256 amount
    ) internal {
        mintShareEnergy();
        EnergyProduceData += amount;
        mintAvatarEnergy(avatarId);
        AvatarEnergys[avatarId] += amount;
        mintCollectionEnergy(COID);
        CollectionEnergys[COID] += amount;
        mintPassHolderEnergy(PassId);
        PassHolderEnergys[PassId] += amount;
    }

    function subEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId
    ) public onlyMap {
        _subEAW(avatarId, COID, PassId);
    }

    function _subEAW(uint256 avatarId, uint256 COID, uint32 PassId) internal {
        mintShareEnergy();
        uint256 amount = getAvatarEAW(avatarId);
        EnergyProduceData -= amount;
        mintAvatarEnergy(avatarId);
        AvatarEnergys[avatarId] -= amount;
        mintCollectionEnergy(COID);
        CollectionEnergys[COID] -= amount;
        mintPassHolderEnergy(PassId);
        PassHolderEnergys[PassId] -= amount;
    }

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

    function mintShareEnergy() public {
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

    function getAvatarEnergyInbox(
        uint256 avatarId
    ) internal view returns (uint256) {
        return AvatarEnergys[avatarId] / 10 ** 50;
    }

    function getAvatarPerEAWMinted(
        uint256 avatarId
    ) internal view returns (uint256) {
        return (AvatarEnergys[avatarId] % 10 ** 50) / 10 ** 25;
    }

    function getAvatarEAW(uint256 avatarId) internal view returns (uint256) {
        return AvatarEnergys[avatarId] % 10 ** 25;
    }

    function mintAvatarEnergy(uint256 avatarId) internal {
        uint256 AvatarPerEAWMinted = getAvatarPerEAWMinted(avatarId);
        uint256 PerEAWMinted = getPerEAWMinted();
        if (AvatarPerEAWMinted < PerEAWMinted) {
            uint256 AvatarEAW = getAvatarEAW(avatarId);
            uint256 AvatarEnergyInbox = getAvatarEnergyInbox(avatarId);
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

    function getAvatarInboxEnergy(
        uint256 avatarId
    ) public view returns (uint256 inbox) {
        uint256 PerEAWMinted = getPerEAWMinted();
        inbox = getAvatarEnergyInbox(avatarId);
        uint256 AvatarPerEAWMinted = getAvatarPerEAWMinted(avatarId);
        uint256 AvatarEAW = getAvatarEAW(avatarId);

        if (AvatarPerEAWMinted < PerEAWMinted && AvatarEAW > 0) {
            inbox +=
                (((PerEAWMinted - AvatarPerEAWMinted) * AvatarEAW) * 90) /
                100;
        }
    }

    function redeemAvatarInboxEnergy(uint256 avatarId) public {
        require(
            msg.sender == IAvatar(avatarContract).ownerOf(avatarId),
            "not your avatar"
        );
        mintShareEnergy();
        mintAvatarEnergy(avatarId);

        uint256 amount = getAvatarEnergyInbox(avatarId);
        require(amount > 0, "empty");

        AvatarEnergys[avatarId] = AvatarEnergys[avatarId] % (10 ** 50);
        IEnergy(energyContract).mint(msg.sender, amount);
    }

    function getCollectionEnergyInbox(
        uint256 COID
    ) internal view returns (uint256) {
        return CollectionEnergys[COID] / 10 ** 50;
    }

    function getCollectionPerEAWMinted(
        uint256 COID
    ) internal view returns (uint256) {
        return (CollectionEnergys[COID] % 10 ** 50) / 10 ** 25;
    }

    function getCollectionEAW(uint256 COID) internal view returns (uint256) {
        return CollectionEnergys[COID] % 10 ** 25;
    }

    function mintCollectionEnergy(uint256 COID) internal {
        uint256 PerEAWMinted = getPerEAWMinted();
        uint256 CollectionPerEAWMinted = getCollectionPerEAWMinted(COID);
        if (CollectionPerEAWMinted < PerEAWMinted) {
            uint256 CollectionEAW = getCollectionEAW(COID);
            uint256 CollectionEnergyInbox = getCollectionEnergyInbox(COID);
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

    function getCollectionInboxEnergy(
        uint256 COID
    ) public view returns (uint256 inbox) {
        uint256 PerEAWMinted = getPerEAWMinted();
        inbox = getCollectionEnergyInbox(COID);
        uint256 CollectionPerEAWMinted = getCollectionPerEAWMinted(COID);
        uint256 CollectionEAW = getCollectionEAW(COID);

        if (CollectionPerEAWMinted < PerEAWMinted && CollectionEAW > 0) {
            inbox +=
                (((PerEAWMinted - CollectionPerEAWMinted) * CollectionEAW) *
                    9) /
                100;
        }
    }

    function redeemCollectionInboxEnergy(
        uint256 avatarId,
        uint256 COID
    ) public onlyAvatar {
        uint256 amount = getCollectionEnergyInbox(COID);
        if (amount > 0) {
            amount = amount / (getCollectionOnMapNum(COID) + 1);
            CollectionEnergys[COID] -= amount * (10 ** 50);
            AvatarEnergys[avatarId] += amount * (10 ** 50);
        }
    }

    function getPassHolderEnergyInbox(
        uint32 PassId
    ) internal view returns (uint256) {
        return PassHolderEnergys[PassId] / 10 ** 50;
    }

    function getPassHolderPerEAWMinted(
        uint32 PassId
    ) internal view returns (uint256) {
        return (PassHolderEnergys[PassId] % 10 ** 50) / 10 ** 25;
    }

    function getPassHolderEAW(uint32 PassId) internal view returns (uint256) {
        return PassHolderEnergys[PassId] % 10 ** 25;
    }

    function mintPassHolderEnergy(uint32 PassId) internal {
        uint256 PerEAWMinted = getPerEAWMinted();
        uint256 PassHolderPerEAWMinted = getPassHolderPerEAWMinted(PassId);
        if (PassHolderPerEAWMinted < PerEAWMinted) {
            uint256 PassHolderEAW = getPassHolderEAW(PassId);
            uint256 PassHolderEnergyInbox = getPassHolderEnergyInbox(PassId);
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

    function getPassHolderInboxEnergy(
        uint32 PassId
    ) public view returns (uint256 inbox) {
        uint256 PerEAWMinted = getPerEAWMinted();
        inbox = getPassHolderEnergyInbox(PassId);
        uint256 PassHolderPerEAWMinted = getPassHolderPerEAWMinted(PassId);
        uint256 PassHolderEAW = getPassHolderEAW(PassId);

        if (PassHolderPerEAWMinted < PerEAWMinted && PassHolderEAW > 0) {
            inbox +=
                ((PerEAWMinted - PassHolderPerEAWMinted) * PassHolderEAW) /
                100;
        }
    }

    function redeemPassHolderInboxEnergy(uint32 PassId) public onlyAvatar {
        require(
            msg.sender == IERC721(passContract).ownerOf(PassId),
            "not your pass"
        );
        mintShareEnergy();
        mintPassHolderEnergy(PassId);

        uint256 amount = getPassHolderEnergyInbox(PassId);
        require(amount > 0, "empty");

        PassHolderEnergys[PassId] = PassHolderEnergys[PassId] % (10 ** 50);
        IEnergy(energyContract).mint(msg.sender, amount);
    }

    bytes32 public whiteListRoot;

    // Collection Id
    uint256 COIDCounter;

    mapping(uint256 => address) public COIDMap;

    /**
     * @notice record the collection's COID and number of collection nfts which is standing on the map with last 6 digit
     * Collection address => COID * 1000000 + on map nft number
     */
    mapping(address => uint256) public collectionMap;

    function getCollectionContract(uint256 COID) public view returns (address) {
        return COIDMap[COID];
    }

    function getCollectionCOID(
        address collectionContract
    ) public view returns (uint256) {
        return collectionMap[collectionContract] / 1000000;
    }

    function getCollectionsCOIDs(
        address[] memory collectionContracts
    ) public view returns (uint256[] memory COIDs) {
        COIDs = new uint256[](collectionContracts.length);
        for (uint256 i = 0; i < collectionContracts.length; i++) {
            COIDs[i] = collectionMap[collectionContracts[i]] / 1000000;
        }
    }

    function generateCOID(
        address collectionContract
    ) internal returns (uint256) {
        COIDCounter++;
        COIDMap[COIDCounter] = collectionContract;
        collectionMap[collectionContract] = COIDCounter * 1000000;
        return COIDCounter;
    }

    function checkWhitelistCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) public returns (uint256 COID) {
        COID = getCollectionCOID(collectionContract);
        if (COID == 0) {
            require(
                isInWhiteList(collectionContract, proofs),
                "not in whitelist"
            );
            COID = generateCOID(collectionContract);
        }
    }

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

    function updateWhiteList(bytes32 whiteListRoot_) public onlyOwner {
        whiteListRoot = whiteListRoot_;
    }

    function addCollectionOnMapNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)]++;
    }

    function subCollectionOnMapNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)]--;
    }

    function getCollectionOnMapNum(uint256 COID) public view returns (uint256) {
        return collectionMap[getCollectionContract(COID)] % 1000000;
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
