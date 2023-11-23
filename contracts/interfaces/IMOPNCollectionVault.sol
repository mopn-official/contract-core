// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IMOPNCollectionVault is IERC20 {
    struct AskStruct {
        uint256 vaultStatus;
        uint256 startBlock;
        uint256 bidAcceptPrice;
        uint256 tokenId;
        uint256 currentPrice;
    }

    struct BidStruct {
        uint256 vaultStatus;
        uint256 startBlock;
        uint256 Coefficient;
    }

    event BidAccept(address indexed operator, uint256 tokenId, uint256 price);

    event AskAccept(address indexed operator, uint256 tokenId, uint256 price);

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

    function getAskInfo() external view returns (AskStruct memory auction);

    function MTBalance() external view returns (uint256 balance);

    function collectionAddress() external view returns (address);

    function V2MTAmountRealtime(
        uint256 VAmount
    ) external view returns (uint256 MTAmount);
}
