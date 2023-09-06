// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMOCKNFTMiner {
    function registerCollection() external;
}

contract MOCKNFT is ERC721A, Ownable {
    string public baseURI;

    string public uriext;

    constructor(
        address mocknftminer,
        string memory name_,
        string memory symbol_,
        string memory baseuri_,
        string memory uriext_
    ) ERC721A(name_, symbol_) {
        IMOCKNFTMiner(mocknftminer).registerCollection();
        baseURI = baseuri_;
        uriext = uriext_;
    }

    function safeMint(address to, uint256 amount) public {
        _safeMint(to, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setURIExt(string memory uriext_) public onlyOwner {
        uriext = uriext_;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return string.concat(super.tokenURI(_tokenId), uriext);
    }
}
