// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IArsenal {
    function buy(uint256 propId, uint256 amount, uint256 round) external;

    function getCurrentRound()
        external
        view
        returns (uint256 roundId, uint256 roundCloseTime);

    function getPropCurrentRoundData(
        uint256 propId
    ) external view returns (uint256 price, uint256 amoutLeft);
}
