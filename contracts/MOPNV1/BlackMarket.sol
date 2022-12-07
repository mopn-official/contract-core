// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BlackMarket is Initializable {
    function sellOrder(uint256 armsId, uint256 price) public returns (uint256 orderId) {}
    function buyOrder(uint256 armsId, uint256 price) public returns (uint256 orderId) {}
    function makeOrder(uint256 orderId) public {}
}
