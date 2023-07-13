// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPNLandMetaDataRender.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNLand is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 10981;

    uint256 private _tokenIdCounter;

    constructor() ERC721("MOPNLand", "Land") {}

    function claim(address to, uint256 tokenId) public onlyOwner {
        if (_exists(tokenId)) {
            _transfer(ownerOf(tokenId), to, tokenId);
        } else {
            _mint(to, tokenId);
            if (tokenId > _tokenIdCounter) {
                _tokenIdCounter = tokenId;
            }
        }
    }

    function auctionMint(address to, uint256 amount) public {
        require(
            msg.sender == auctionAddress,
            "only allowed call by mopn auction"
        );
        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter++;
            _mint(to, _tokenIdCounter);
        }
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter + 1;
    }

    address public metadataRenderAddress;

    address public auctionAddress;

    function setRender(address metaDataRenderAddress_) public onlyOwner {
        metadataRenderAddress = metaDataRenderAddress_;
    }

    function setAuction(address auctionAddress_) public onlyOwner {
        auctionAddress = auctionAddress_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory tokenuri) {
        _requireMinted(tokenId);

        if (metadataRenderAddress != address(0)) {
            IMOPNLandMetaDataRender metaDataRender = IMOPNLandMetaDataRender(
                metadataRenderAddress
            );
            tokenuri = metaDataRender.constructTokenURI(tokenId);
        }
    }
}
