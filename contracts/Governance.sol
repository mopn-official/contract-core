// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    uint256 constant BEP = 600000000000000000000000;

    uint256 constant BEP_REDUCE_INTERVAL = 50000;

    uint256 BEPSStartBlock;

    // Block Energy Produce Share Minted
    uint256 BEPSMinted;

    uint256 BEPSLastMiningBlockNumber;

    uint256 BEPS_Count;

    mapping(uint256 => uint256) public AvatarCalcEnergy;

    mapping(uint256 => uint256) public AvatarBEPSShare;

    mapping(uint256 => uint256) public AvatarInboxEnergy;

    mapping(uint256 => uint256) public CollectionCalcEnergy;

    mapping(uint256 => uint256) public CollectionBEPSShare;

    mapping(uint256 => uint256) public CollectionInboxEnergy;

    mapping(uint256 => uint256) public PassHolderCalcEnergy;

    mapping(uint256 => uint256) public PassHolderBEPSShare;

    mapping(uint256 => uint256) public PassHolderInboxEnergy;

    constructor(uint256 BEPSStartBlock_) {
        BEPSStartBlock = BEPSStartBlock_;
    }

    function addBEPS(
        uint256 avatarId,
        uint256 COID,
        uint64 PassId,
        uint256 amount
    ) public onlyMap {
        mintShareEnergy();
        BEPS_Count += amount;
        mintAvatarEnergy(avatarId);
        AvatarBEPSShare[avatarId] += amount;
        mintCollectionEnergy(COID);
        CollectionBEPSShare[COID] += amount;
        mintPassHolderEnergy(PassId);
        PassHolderBEPSShare[PassId] += amount;
    }

    function subBEPS(
        uint256 avatarId,
        uint256 COID,
        uint64 PassId,
        uint256 amount
    ) public onlyMap {
        mintShareEnergy();
        BEPS_Count -= amount;
        mintAvatarEnergy(avatarId);
        console.log("1:", AvatarBEPSShare[avatarId]);
        console.log("2:", amount);
        AvatarBEPSShare[avatarId] -= amount;
        mintCollectionEnergy(COID);
        CollectionBEPSShare[COID] -= amount;
        mintPassHolderEnergy(PassId);
        PassHolderBEPSShare[PassId] -= amount;
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

    function mintAvatarEnergy(uint256 avatarId) internal {
        if (AvatarCalcEnergy[avatarId] < BEPSMinted) {
            if (AvatarBEPSShare[avatarId] > 0) {
                uint256 add = ((BEPSMinted - AvatarCalcEnergy[avatarId]) *
                    AvatarBEPSShare[avatarId]);
                AvatarInboxEnergy[avatarId] += (add * 90) / 100;
            }
            AvatarCalcEnergy[avatarId] = BEPSMinted;
        }
    }

    function mintCollectionEnergy(uint256 COID) internal {
        if (CollectionCalcEnergy[COID] < BEPSMinted) {
            if (CollectionBEPSShare[COID] > 0) {
                uint256 add = ((BEPSMinted - CollectionCalcEnergy[COID]) *
                    CollectionBEPSShare[COID]);
                CollectionInboxEnergy[COID] += (add * 9) / 100;
            }
            CollectionCalcEnergy[COID] = BEPSMinted;
        }
    }

    function mintPassHolderEnergy(uint64 PassId) internal {
        if (PassHolderCalcEnergy[PassId] < BEPSMinted) {
            if (PassHolderBEPSShare[PassId] > 0) {
                uint256 add = ((BEPSMinted - PassHolderCalcEnergy[PassId]) *
                    PassHolderBEPSShare[PassId]);
                PassHolderInboxEnergy[PassId] += add / 100;
            }
            PassHolderCalcEnergy[PassId] = BEPSMinted;
        }
    }

    function currentBEP(uint256 reduceTimes) public pure returns (uint256) {
        return (BEP * 997 ** reduceTimes) / (1000 ** reduceTimes);
    }

    function getAvatarInboxEnergy(
        uint256 avatarId
    ) public view returns (uint256) {
        return AvatarInboxEnergy[avatarId];
    }

    function redeemAvatarInboxEnergy(uint256 avatarId) public {
        mintShareEnergy();
        mintAvatarEnergy(avatarId);

        require(AvatarInboxEnergy[avatarId] > 0, "empty");
        uint256 amount = AvatarInboxEnergy[avatarId];
        AvatarInboxEnergy[avatarId] = 0;
        IEnergy(energyContract).mint(msg.sender, amount);
    }

    bytes32 public whiteListRoot;

    function checkWhitelistCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) public returns (uint256) {
        if (COIDMap[collectionContract] == 0) {
            require(
                isInWhiteList(collectionContract, proofs),
                "not in whitelist"
            );
            generateCOID(collectionContract);
        }
        return COIDMap[collectionContract];
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

    // Collection Id
    uint256 COIDCounter;

    mapping(address => uint256) public COIDMap;

    function getCOID(address collectionContract) public view returns (uint256) {
        return COIDMap[collectionContract];
    }

    function generateCOID(address collectionContract) internal {
        COIDCounter++;
        COIDMap[collectionContract] = COIDCounter;
    }

    // Bomb
    function mintBomb(address to, uint256 amount) public onlyArsenal {
        IBomb(bombContract).mint(to, 1, amount);
    }

    function burnBomb(address from, uint256 amount) public onlyAvatar {
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
