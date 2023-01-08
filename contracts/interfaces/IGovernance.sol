// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/Structs.sol";

interface IGovernance {
    function stakePass(uint256 tokenId) external;

    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) external view returns (bool);

    function getCollectionData(
        address collectionContract
    ) external view returns (CollectionData memory);
}
