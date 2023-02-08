// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract Governance is Multicall, Ownable {
    uint256 constant BEP = 600000000000;

    uint256 constant BEP_REDUCE_INTERVAL = 50000;

    uint256 BEPSStartBlock;

    // Block Energy Produce Share Minted
    uint256 BEPSMinted;

    uint256 BEPSLastMiningBlockNumber;

    uint256 BEPS_Count;

    mapping(uint256 => uint256) public AvatarEnergys;

    mapping(uint256 => uint256) public CollectionEnergys;

    mapping(uint32 => uint256) public PassHolderEnergys;

    constructor(uint256 BEPSStartBlock_) {
        BEPSStartBlock = BEPSStartBlock_;
    }

    function addBEPS(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId,
        uint256 amount
    ) public onlyMap {
        _addBEPS(avatarId, COID, PassId, amount);
    }

    function _addBEPS(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId,
        uint256 amount
    ) internal {
        mintShareEnergy();
        BEPS_Count += amount;
        mintAvatarEnergy(avatarId);
        AvatarEnergys[avatarId] += amount;
        mintCollectionEnergy(COID);
        CollectionEnergys[COID] += amount;
        mintPassHolderEnergy(PassId);
        PassHolderEnergys[PassId] += amount;
    }

    function subBEPS(
        uint256 avatarId,
        uint256 COID,
        uint32 PassId
    ) public onlyMap {
        _subBEPS(avatarId, COID, PassId);
    }

    function _subBEPS(uint256 avatarId, uint256 COID, uint32 PassId) internal {
        mintShareEnergy();
        uint256 amount = getAvatarBEPSShare(avatarId);
        BEPS_Count -= amount;
        mintAvatarEnergy(avatarId);
        AvatarEnergys[avatarId] -= amount;
        mintCollectionEnergy(COID);
        CollectionEnergys[COID] -= amount;
        mintPassHolderEnergy(PassId);
        PassHolderEnergys[PassId] -= amount;
    }

    function mintShareEnergy() public {
        if (BEPS_Count == 0) {
            BEPSLastMiningBlockNumber = block.number;
        } else if (block.number > BEPSLastMiningBlockNumber) {
            uint256 reduceTimes = (BEPSLastMiningBlockNumber - BEPSStartBlock) /
                BEP_REDUCE_INTERVAL;
            uint256 nextReduceBlockNumber = BEPSStartBlock +
                BEP_REDUCE_INTERVAL +
                reduceTimes *
                BEP_REDUCE_INTERVAL;

            uint256 BEPSMinted_;
            while (true) {
                if (block.number > nextReduceBlockNumber) {
                    BEPSMinted_ +=
                        ((nextReduceBlockNumber - BEPSLastMiningBlockNumber) *
                            currentBEP(reduceTimes)) /
                        BEPS_Count;
                    BEPSLastMiningBlockNumber = nextReduceBlockNumber;
                    reduceTimes++;
                    nextReduceBlockNumber += BEP_REDUCE_INTERVAL;
                } else {
                    BEPSMinted_ +=
                        ((block.number - BEPSLastMiningBlockNumber) *
                            currentBEP(reduceTimes)) /
                        BEPS_Count;
                    break;
                }
            }

            BEPSMinted += BEPSMinted_;
            BEPSLastMiningBlockNumber = block.number;
        }
    }

    function getAvatarBEPSMinted(
        uint256 avatarId
    ) internal view returns (uint256) {
        return (AvatarEnergys[avatarId] % 10 ** 50) / 10 ** 25;
    }

    function getCollectionBEPSMinted(
        uint256 COID
    ) internal view returns (uint256) {
        return (CollectionEnergys[COID] % 10 ** 50) / 10 ** 25;
    }

    function getPassHolderBEPSMinted(
        uint32 PassId
    ) internal view returns (uint256) {
        return (PassHolderEnergys[PassId] % 10 ** 50) / 10 ** 25;
    }

    function getAvatarBEPSInbox(
        uint256 avatarId
    ) internal view returns (uint256) {
        return AvatarEnergys[avatarId] / 10 ** 50;
    }

    function getCollectionBEPSInbox(
        uint256 COID
    ) internal view returns (uint256) {
        return CollectionEnergys[COID] / 10 ** 50;
    }

    function getPassHolderBEPSInbox(
        uint32 PassId
    ) internal view returns (uint256) {
        return PassHolderEnergys[PassId] / 10 ** 50;
    }

    function getAvatarBEPSShare(
        uint256 avatarId
    ) internal view returns (uint256) {
        return AvatarEnergys[avatarId] % 10 ** 25;
    }

    function getCollectionBEPSShare(
        uint256 COID
    ) internal view returns (uint256) {
        return CollectionEnergys[COID] % 10 ** 25;
    }

    function getPassHolderBEPSShare(
        uint32 PassId
    ) internal view returns (uint256) {
        return PassHolderEnergys[PassId] % 10 ** 25;
    }

    function mintAvatarEnergy(uint256 avatarId) internal {
        uint256 AvatarBEPSMinted = getAvatarBEPSMinted(avatarId);
        if (AvatarBEPSMinted < BEPSMinted) {
            uint256 AvatarBEPSShare = getAvatarBEPSShare(avatarId);
            uint256 AvatarBEPSInbox = getAvatarBEPSInbox(avatarId);
            if (AvatarBEPSShare > 0) {
                AvatarBEPSInbox += ((((BEPSMinted - AvatarBEPSMinted) *
                    AvatarBEPSShare) * 90) / 100);
            }
            AvatarEnergys[avatarId] =
                AvatarBEPSInbox *
                10 ** 50 +
                BEPSMinted *
                10 ** 25 +
                AvatarBEPSShare;
        }
    }

    function mintCollectionEnergy(uint256 COID) internal {
        uint256 CollectionBEPSMinted = getCollectionBEPSMinted(COID);
        if (CollectionBEPSMinted < BEPSMinted) {
            uint256 CollectionBEPSShare = getCollectionBEPSShare(COID);
            uint256 CollectionBEPSInbox = getCollectionBEPSInbox(COID);
            if (CollectionBEPSShare > 0) {
                CollectionBEPSInbox += ((((BEPSMinted - CollectionBEPSMinted) *
                    CollectionBEPSShare) * 9) / 100);
            }
            CollectionEnergys[COID] =
                CollectionBEPSInbox *
                10 ** 50 +
                BEPSMinted *
                10 ** 25 +
                CollectionBEPSShare;
        }
    }

    function mintPassHolderEnergy(uint32 PassId) internal {
        uint256 PassHolderBEPSMinted = getPassHolderBEPSMinted(PassId);
        if (PassHolderBEPSMinted < BEPSMinted) {
            uint256 PassHolderBEPSShare = getPassHolderBEPSShare(PassId);
            uint256 PassHolderBEPSInbox = getPassHolderBEPSInbox(PassId);
            if (PassHolderBEPSShare > 0) {
                PassHolderBEPSInbox +=
                    ((BEPSMinted - PassHolderBEPSMinted) *
                        PassHolderBEPSShare) /
                    100;
            }
            PassHolderEnergys[PassId] =
                PassHolderBEPSInbox *
                10 ** 50 +
                BEPSMinted *
                10 ** 25 +
                PassHolderBEPSShare;
        }
    }

    function currentBEP(
        uint256 reduceTimes
    ) public pure returns (uint256 cBEP) {
        cBEP = BEP;
        while (true) {
            if (reduceTimes > 17) {
                cBEP = (BEP * 997 ** 17) / (1000 ** 17);
            } else {
                cBEP = (BEP * 997 ** reduceTimes) / (1000 ** reduceTimes);
                break;
            }
            reduceTimes -= 17;
        }
    }

    function getAvatarInboxEnergy(
        uint256 avatarId
    ) public view returns (uint256 inbox) {
        inbox = getAvatarBEPSInbox(avatarId);
        uint256 AvatarBEPSMinted = getAvatarBEPSMinted(avatarId);
        uint256 AvatarBEPSShare = getAvatarBEPSShare(avatarId);

        if (AvatarBEPSMinted < BEPSMinted) {
            if (AvatarBEPSShare > 0) {
                inbox +=
                    (((BEPSMinted - AvatarBEPSMinted) * AvatarBEPSShare) * 90) /
                    100;
            }
        }
    }

    function redeemAvatarInboxEnergy(uint256 avatarId) public {
        require(
            msg.sender == IAvatar(avatarContract).ownerOf(avatarId),
            "not your avatar"
        );
        mintShareEnergy();
        mintAvatarEnergy(avatarId);

        uint256 amount = getAvatarBEPSInbox(avatarId);
        require(amount > 0, "empty");

        AvatarEnergys[avatarId] = AvatarEnergys[avatarId] % (10 ** 50);
        IEnergy(energyContract).mint(msg.sender, amount);
    }

    function redeemCollectionInboxEnergy(
        uint256 avatarId,
        uint256 COID,
        uint256 onMapAvatarNum
    ) public onlyAvatar {
        uint256 amount = getCollectionBEPSInbox(COID);
        if (amount > 0) {
            amount = amount / (onMapAvatarNum + 1);
            CollectionEnergys[COID] -= amount * (10 ** 50);
            AvatarEnergys[avatarId] += amount * (10 ** 50);
        }
    }

    bytes32 public whiteListRoot;

    // Collection Id
    uint256 COIDCounter;

    mapping(uint256 => address) public COIDMap;

    mapping(address => uint256) public collectionMap;

    function getCollectionContract(uint256 COID) public view returns (address) {
        return COIDMap[COID];
    }

    function generateCOID(address collectionContract) internal {
        COIDCounter++;
        COIDMap[COIDCounter] = collectionContract;
        collectionMap[collectionContract] = COIDCounter;
    }

    function checkWhitelistCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) public returns (uint256) {
        if (collectionMap[collectionContract] == 0) {
            require(
                isInWhiteList(collectionContract, proofs),
                "not in whitelist"
            );
            generateCOID(collectionContract);
        }
        return collectionMap[collectionContract];
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
            _addBEPS(avatarId, COID, PassId, 1);
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
