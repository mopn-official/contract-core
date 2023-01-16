// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    struct AvatarStat {
        uint256 startRound;
        uint256 lastCollectTimeStamp;
    }
    struct CollectionBLERRound {
        uint256 participants;
        uint256 amount;
    }
    struct CollectionBLERRounds {
        uint256 BLER;
        uint256 currentRound;
        mapping(uint256 => CollectionBLERRound) Rounds;
    }
    address public energyContract;

    address public passContract;

    address public avatarContract;

    address public mapContract;

    bytes32 public whiteListRoot;

    uint256 COIDCounter;

    mapping(address => uint256) public COIDMap;

    mapping(uint256 => CollectionBLERRounds) public CollctionBLER;

    mapping(uint256 => AvatarStat) public AvatarStats;

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

    function updateMapContract(address mapContract_) public onlyOwner {
        mapContract = mapContract_;
    }

    function updateAvatarContract(address avatarContract_) public onlyOwner {
        avatarContract = avatarContract_;
    }

    function updatePassContract(address passContract_) public onlyOwner {
        passContract = passContract_;
    }

    function getCOID(address collectionContract) public view returns (uint256) {
        return COIDMap[collectionContract];
    }

    function generateCOID(address collectionContract) internal {
        COIDCounter++;
        COIDMap[collectionContract] = COIDCounter;
    }

    function addCollectionBLER(uint256 COID, uint256 bler) public onlyAvatar {
        CollctionBLER[COID].BLER += bler;
    }

    function SubCollectionBLER(uint256 COID, uint256 bler) public onlyAvatar {
        CollctionBLER[COID].BLER -= bler;
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
