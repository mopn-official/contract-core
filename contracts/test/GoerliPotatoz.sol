// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GoerliPotatoz is ERC721A, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721A("GoerliPotatoz", "GoerliPotatoz") {}

    function safeMint(address to, uint256 amount) public {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    string public baseURI = "https://grow-api.memeland.com/token/metadata/";

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return string.concat(super.tokenURI(_tokenId), ".json");
    }
}
