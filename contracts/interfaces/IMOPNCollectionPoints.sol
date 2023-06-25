// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMOPNCollectionPoints {
    function createCollectionVault(uint256 COID) external returns (address);

    function getCollectionVault(uint256 COID) external view returns (address);
}
