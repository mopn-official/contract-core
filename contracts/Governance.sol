// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    address public energyContract;

    address public passContract;

    bytes32 public whiteListRoot;

    uint256 COIDCounter;

    mapping(address => uint256) public COIDMap;

    mapping(uint256 => uint256) public CollctionBLER;

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

    function getCOID(address collectionContract) public view returns (uint256) {
        return COIDMap[collectionContract];
    }

    function generateCOID(address collectionContract) internal {
        COIDCounter++;
        COIDMap[collectionContract] = COIDCounter;
    }
}
