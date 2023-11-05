// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TESTNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    constructor(
        address initialOwner
    ) ERC721("MOPNTest1", "MOPNTest1") Ownable(initialOwner) {}

    function safeMint(address to, uint256 amount) public {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter);
            _tokenIdCounter++;
        }
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter;
    }

    string public baseURI;

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
