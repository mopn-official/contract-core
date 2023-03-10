// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface ILand is IERC721 {
    function auctionMint(address to, uint256 amount) external;

    function nextTokenId() external view returns (uint256);
}
