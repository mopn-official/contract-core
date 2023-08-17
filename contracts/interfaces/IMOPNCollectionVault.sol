// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IMOPNCollectionVault is IERC20 {
    struct NFTAuction {
        uint256 offerStatus;
        uint256 startTimestamp;
        uint256 offerAcceptPrice;
        uint256 tokenId;
        uint256 currentPrice;
    }

    event NFTOfferAccept(
        address indexed operator,
        uint256 tokenId,
        uint256 price,
        uint256 oldNFTOfferCoefficient,
        uint256 newNFTOfferCoefficient
    );

    event NFTAuctionAccept(
        address indexed operator,
        uint256 tokenId,
        uint256 price
    );

    event MTDeposit(
        address indexed operator,
        uint256 MTAmount,
        uint256 VTAmount
    );

    event MTWithdraw(
        address indexed operator,
        uint256 MTAmount,
        uint256 VTAmount
    );

    function getAuctionInfo() external view returns (NFTAuction memory auction);

    function MTBalance() external view returns (uint256 balance);

    function collectionAddress() external view returns (address);
}
