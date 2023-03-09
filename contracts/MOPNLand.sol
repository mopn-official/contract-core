// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ILandMetaDataRender.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MOPNLand is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MOPNLand", "Land") {}

    function auctionMint(address to, uint256 amount) public {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    address public metaDataRenderAddress;

    function setMetaDataRender(
        address metaDataRenderAddress_
    ) public onlyOwner {
        metaDataRenderAddress = metaDataRenderAddress_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory tokenuri) {
        _requireMinted(tokenId);

        if (metaDataRenderAddress != address(0)) {
            ILandMetaDataRender metaDataRender = ILandMetaDataRender(
                metaDataRenderAddress
            );
            tokenuri = metaDataRender.constructTokenURI(tokenId);
        }
    }
}
