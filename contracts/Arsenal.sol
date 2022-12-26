// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Arsenal is Initializable {
    address public forgeContract;

    uint256 public roundClosePeriod;

    function buy(uint256 propId, uint256 amount, uint256 round) public {}

    function getCurrentRound() public view returns (uint256 roundId, uint256 roundCloseTime) {}

    function getPropCurrentRoundData(uint256 propId)
        public
        view
        returns (uint256 roundId, uint256 price, uint256 amoutLeft, uint256 roundCloseTime)
    {}
}
