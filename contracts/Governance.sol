// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct CollectionData {
    uint256 colour;
    string thumbDirCid;
}

contract Governance is Ownable {
    address public energyContract;

    address public passContract;

    bytes32 public whiteListRoot;

    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                proofs,
                whiteListRoot,
                keccak256(abi.encodePacked(collectionContract))
            );
    }

    function updateWhiteList(bytes32 whiteListRoot_) public onlyOwner {
        whiteListRoot = whiteListRoot_;
    }
}
