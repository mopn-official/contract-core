// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

struct CollectionData {
    uint256 colour;
    string thumbDirCid;
}

contract Governance is Initializable, IERC721ReceiverUpgradeable {
    address public energyContract;

    address public passContract;

    bytes32 public whiteListRoot;

    mapping(address => uint256) public passStakers;

    function stakePass(uint256 tokenId) public {}

    function isInWhiteList(address collectionContract, bytes32[] memory proofs) public view returns (bool) {}

    function getCollectionData(address collectionContract) public view returns (CollectionData memory) {}

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata)
        external
        returns (bytes4)
    {
        require(from == passContract, "only receive pass nft");
        passStakers[operator] = tokenId;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}
