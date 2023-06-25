// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAvatar.sol";

interface IGovernance {
    function updateWhiteList(bytes32 whiteListRoot_) external;

    function mintMT(address to, uint256 amount) external;

    function mintBomb(address to, uint256 amount) external;

    function burnBomb(address from, uint256 amount) external;

    function whiteListRoot() external view returns (bytes32);

    function auctionHouseContract() external view returns (address);

    function avatarContract() external view returns (address);

    function bombContract() external view returns (address);

    function mtContract() external view returns (address);

    function mapContract() external view returns (address);

    function landContract() external view returns (address);

    function miningDataContract() external view returns (address);

    function createCollectionVault(uint256 COID) external returns (address);

    function getCollectionVault(uint256 COID) external view returns (address);
}
