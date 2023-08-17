// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPNData {
    function calcPerMOPNPointMinted() external view returns (uint256 inbox);

    function calcCollectionSettledMT(
        address collectionAddress
    ) external view returns (uint256 inbox);

    function calcAccountMT(
        address account
    ) external view returns (uint256 inbox);
}
