// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAvatar.sol";

interface IGovernance {
    function getCollectionContract(
        uint256 COID
    ) external view returns (address);

    function getCollectionCOID(
        address collectionContract
    ) external view returns (uint256);

    function getCollectionsCOIDs(
        address[] memory collectionContracts
    ) external view returns (uint256[] memory COIDs);

    function generateCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) external returns (uint256);

    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) external view returns (bool);

    function updateWhiteList(bytes32 whiteListRoot_) external;

    function addCollectionOnMapNum(uint256 COID) external;

    function subCollectionOnMapNum(uint256 COID) external;

    function getCollectionOnMapNum(
        uint256 COID
    ) external view returns (uint256);

    function addCollectionAvatarNum(uint256 COID) external;

    function getCollectionAvatarNum(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionMintedMT(
        uint256 COID
    ) external view returns (uint256);

    function addCollectionMintedMT(uint256 COID, uint256 amount) external;

    function clearCollectionMintedMT(uint256 COID) external;

    function getCollectionVault(uint256 COID) external view returns (address);

    function mintMT(address to, uint256 amount) external;

    function mintBomb(address to, uint256 amount) external;

    function burnBomb(address from, uint256 amount) external;

    function auctionHouseContract() external view returns (address);

    function avatarContract() external view returns (address);

    function bombContract() external view returns (address);

    function mtContract() external view returns (address);

    function mapContract() external view returns (address);

    function landContract() external view returns (address);

    function miningDataContract() external view returns (address);
}
