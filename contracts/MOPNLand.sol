// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ILandMetaDataRender.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ICrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

contract MOPNLand is ERC721, Ownable, ReentrancyGuard {
    ICrossDomainMessenger public immutable MESSENGER;
    address public metadataRenderAddress;
    address public mainnetClaimer;

    constructor(
        address _messenger,
        address _metadataRenderAddress,
        address initialOwner
    ) ERC721("MOPNLAND BLAST", "LAND") Ownable(initialOwner) {
        MESSENGER = ICrossDomainMessenger(_messenger);
        metadataRenderAddress = _metadataRenderAddress;
    }

    function setMainnetClaimer(address _mainnetClaimer) external onlyOwner {
        mainnetClaimer = _mainnetClaimer;
    }

    function setMetadataRenderAddress(address _metadataRenderAddress) external onlyOwner {
        metadataRenderAddress = _metadataRenderAddress;
    }

    function claim(address _sender, uint256[] memory tokenIds) external  {
        require(
            msg.sender == address(MESSENGER),
            "Greeter: Direct sender must be the CrossDomainMessenger"
        );

        require(
            MESSENGER.xDomainMessageSender() == mainnetClaimer,
            "Greeter: Remote sender must be the other Greeter contract"
        );

        for(uint256 i = 0; i < tokenIds.length; i++){
            _mint(_sender, tokenIds[i]);
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory tokenuri) {
        require(ownerOf(id) != address(0), "not exist");
        require(metadataRenderAddress != address(0), "Invalid metadataRenderAddress");

        ILandMetaDataRender metadataRender = ILandMetaDataRender(metadataRenderAddress);
        tokenuri = metadataRender.constructTokenURI(id);
    }
}
