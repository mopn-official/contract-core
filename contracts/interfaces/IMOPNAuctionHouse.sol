// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IMOPNAuctionHouse is IERC1155 {
    function buyBombFrom(address from, uint256 amount) external;
}
