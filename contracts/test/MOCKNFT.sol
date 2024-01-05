// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

contract MOCKNFT is ERC721AUpgradeable {
    string public baseURI;
    string public extURI;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize(
        string memory name,
        string memory symbol,
        address owner_,
        string memory baseURI_,
        string memory extURI_
    ) public initializerERC721A {
        __ERC721A_init(name, symbol);
        owner = owner_;
        baseURI = baseURI_;
        extURI = extURI_;
    }

    function mint(uint256 quantity) external {
        require(
            (quantity + _numberMinted(msg.sender) <= 20) || msg.sender == owner,
            "wallet mint limit reached"
        );
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setExtURI(string memory extURI_) public onlyOwner {
        extURI = extURI_;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return string.concat(super.tokenURI(_tokenId), extURI);
    }
}
