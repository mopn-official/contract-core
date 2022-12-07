// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Forge is Initializable {
    address public propsContract;

    mapping(uint256 => uint256) public roundSupplies;

    uint256 public startTimestamp;

    uint256 public roundPeriod = 86400;

    function getCurrentRound() public view returns (uint256 round, uint256 roundEndTime) {}

    function getRound(uint256 round) public view returns (uint256 roundEndTime) {}

    function roundSupply(uint256 propId) public view returns (uint256 supply) {}

    function producingProps() public view returns (uint256[] memory propIds) {}
}
