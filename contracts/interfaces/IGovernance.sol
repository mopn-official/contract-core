// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

    function addEAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) external;

    function subEAW(uint256 avatarId, uint256 COID, uint32 LandId) external;

    function mintBomb(address to, uint256 amount) external;

    function mintLand(address to) external;

    function burnBomb(
        address from,
        uint256 amount,
        uint256 avatarId,
        uint256 COID,
        uint32 LandId
    ) external;

    function redeemCollectionInboxEnergy(
        uint256 avatarId,
        uint256 COID
    ) external;

    function getLandHolderRedeemed(
        uint32 LandId
    ) external view returns (uint256);

    function avatarContract() external view returns (address);

    function bombContract() external view returns (address);

    function energyContract() external view returns (address);

    function mapContract() external view returns (address);

    function landContract() external view returns (address);
}
