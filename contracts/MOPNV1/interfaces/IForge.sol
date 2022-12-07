// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IForge {
    function getCurrentRound() external view returns (uint256 round, uint256 roundEndTime);

    function getRound(uint256 round) external view returns (uint256 roundEndTime);

    function roundSupply(uint256 propId) external view returns (uint256 supply);

    function producingProps() external view returns (uint256[] memory propIds);
}
