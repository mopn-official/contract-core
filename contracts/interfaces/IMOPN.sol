// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPN {
    struct AccountDataOutput {
        address account;
        address contractAddress;
        uint256 tokenId;
        uint256 CollectionMOPNPoint;
        uint256 MTBalance;
        uint256 OnMapMOPNPoint;
        uint256 TotalMOPNPoint;
        uint32 tileCoordinate;
        address owner;
        address AgentPlacer;
        uint256 AgentAssignPercentage;
    }

    function owner() external view returns (address);

    function tokenContract() external view returns (address);

    function landContract() external view returns (address);

    function ERC6551AccountHelper() external view returns (address);

    function ERC6551AccountProxy() external view returns (address);

    function MTTotalMinted() external view returns (uint256);

    function TotalMOPNPoints() external view returns (uint256);

    function PerMOPNPointMinted() external view returns (uint256);

    function currentMTPPB() external view returns (uint256);

    function currentMTPPB(uint256 reduceTimes) external view returns (uint256);

    function MTReduceTimes() external view returns (uint256);

    function settlePerMOPNPointMinted() external;

    function settleCollectionMT(address collectionAddress) external;

    function claimCollectionMT(address collectionAddress) external;

    function settleCollectionMOPNPoint(address collectionAddress, uint24 point) external;

    function claimAccountMT(address account) external;

    function getDefault6551AccountImplementation() external view returns (address);

    function checkImplementationExist(address implementation) external view returns (bool);

    function calcPerMOPNPointMinted() external view returns (uint256 inbox);

    function calcCollectionSettledMT(address collectionAddress) external view returns (uint256 inbox);

    function calcAccountMT(address account) external view returns (uint256 inbox);

    function createCollectionVault(address collectionAddress) external returns (address);

    function getCollectionVaultIndex(address collectionAddress) external view returns (uint256);

    function getAccountData(address account) external view returns (AccountDataOutput memory accountData);
}
