// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IArsenal {
    function buy(uint256 amount) external;

    function getCurrentRound() external view returns (uint256);

    function getCurrentPrice() external view returns (uint256);

    function getCurrentRoundData()
        external
        view
        returns (
            uint256 roundId,
            uint256 price,
            uint256 amoutLeft,
            uint256 roundStartTime,
            uint256 roundCloseTime
        );

    function getRoundData(
        uint256 roundId
    )
        external
        view
        returns (
            uint256 price,
            uint256 amoutLeft,
            uint256 roundStartTime,
            uint256 roundCloseTime
        );

    function getRoundPrice(
        uint256 roundId
    ) external view returns (uint256 price);

    function getAgio(address to) external view returns (uint256 agio);

    function redeemAgio() external;
}
