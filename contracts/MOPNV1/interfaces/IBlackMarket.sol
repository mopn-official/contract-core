// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlackMarket {
    function sellOrder(uint256 propId, uint256 price) external returns (uint256 orderId);
    function buyOrder(uint256 propId, uint256 price) external returns (uint256 orderId);
    function makeOrder(uint256 orderId) external;
}
