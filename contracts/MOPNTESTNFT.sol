// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MOPNTESTNFT is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public constant ADDRESS_MINT_LIMIT = 10;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_
    ) ERC721A(name, symbol) {
        baseURI = baseURI_;
    }

    function safeMint(uint256 quantity) public {
        require(
            _numberMinted(msg.sender) + quantity <= ADDRESS_MINT_LIMIT,
            "Exceeds address mint limit"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(msg.sender, quantity);
    }

    string public baseURI;

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/",
                    Strings.toString(tokenId)
                )
            );
    }
}
