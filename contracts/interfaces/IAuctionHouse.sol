// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAuctionHouse {
    function buyBomb(uint256 amount) external;

    function getBombCurrentPrice() external view returns (uint256);

    function getBombCurrentData()
        external
        view
        returns (
            uint256 roundId,
            uint256 price,
            uint256 amoutLeft,
            uint256 roundStartTime,
            uint256 roundCloseTime
        );

    function getBombRoundPrice(uint256 roundId) external view returns (uint256);

    function getAgio(address to) external view returns (uint256 agio);

    function redeemAgio() external;

    function redeemAgioTo(address to) external;
}
