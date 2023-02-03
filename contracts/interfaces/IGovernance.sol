// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/Structs.sol";

interface IGovernance {
    function checkWhitelistCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) external returns (uint256);

    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) external view returns (bool);

    function updateWhiteList(bytes32 whiteListRoot_) external;

    function getCOID(
        address collectionContract
    ) external view returns (uint256);

    function addBEPS(
        uint256 avatarId,
        uint256 COID,
        uint64 PassId,
        uint256 amount
    ) external;

    function subBEPS(
        uint256 avatarId,
        uint256 COID,
        uint64 PassId,
        uint256 amount
    ) external;

    function mintBomb(address to, uint256 amount) external;

    function burnBomb(address from, uint256 amount) external;

    function avatarContract() external view returns (address);

    function bombContract() external view returns (address);

    function energyContract() external view returns (address);

    function mapContract() external view returns (address);

    function passContract() external view returns (address);
}
