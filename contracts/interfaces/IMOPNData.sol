// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPNData {
    event AccountMTMinted(address indexed account, uint256 amount);

    event CollectionMTMinted(address indexed collectionAddress, uint256 amount);

    event LandHolderMTMinted(uint32 indexed LandId, uint256 amount);

    event NFTOfferAccept(
        address indexed collectionAddress,
        uint256 tokenId,
        uint256 price
    );

    event NFTAuctionAccept(
        address indexed collectionAddress,
        uint256 tokenId,
        uint256 price
    );

    event SettleCollectionMOPNPoint(address collectionAddress);

    function MTTotalMinted() external view returns (uint256);

    function PerMOPNPointMinted() external view returns (uint256);

    function TotalMOPNPoints() external view returns (uint256);

    function NFTOfferCoefficient() external view returns (uint256);

    function calcPerMOPNPointMinted() external view returns (uint256);

    function settlePerMOPNPointMinted() external;

    function accountClaimAvailable(
        address account
    ) external view returns (bool);

    function getAccountCollection(
        address account
    ) external view returns (address collectionAddress);

    function getAccountTotalMOPNPoint(
        address account
    ) external view returns (uint256);

    function getAccountPerMOPNPointMinted(
        address account
    ) external view returns (uint256);

    function getAccountCoordinate(
        address account
    ) external view returns (uint32);

    function setAccountCoordinate(address account, uint32 coordinate) external;

    function calcAccountMT(
        address account
    ) external view returns (uint256 inbox);

    function mintAccountMT(address account) external returns (uint256);

    function claimAccountMT(address account) external returns (uint256);

    function getCollectionMOPNPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAdditionalMOPNPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAccountMOPNPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAdditionalMOPNPoint(
        address collectionAddress
    ) external view returns (uint256);

    function setCollectionAdditionalMOPNPoint(
        address collectionAddress,
        uint256 additionalMOPNPoint
    ) external;

    function getCollectionOnMapNum(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionMOPNPoint(
        address collectionAddress
    ) external view returns (uint256);

    function calcCollectionMT(
        address collectionAddress
    ) external view returns (uint256);

    function mintCollectionMT(address collectionAddress) external;

    function claimCollectionMT(address collectionAddressD) external;

    function settleCollectionMining(address collectionAddress) external;

    function settleCollectionMOPNPoint(address collectionAddress) external;

    /**
     * @notice get Land holder realtime unclaimed minted mopn token
     * @param LandId MOPN Land Id
     */
    function getLandHolderInboxMT(
        uint32 LandId
    ) external view returns (uint256 inbox);

    function getLandHolderTotalMinted(
        uint32 LandId
    ) external view returns (uint256);

    function redeemLandHolderMT(uint32 LandId) external;

    function batchRedeemSameLandHolderMT(uint32[] memory LandIds) external;

    function changeTotalMTStaking(
        address collectionAddress,
        bool increase,
        uint256 amount
    ) external;

    function NFTOfferAcceptNotify(
        address collectionAddress,
        uint256 price,
        uint256 tokenId
    ) external;

    function NFTAuctionAcceptNotify(
        address collectionAddress,
        uint256 price,
        uint256 tokenId
    ) external;

    function closeWhiteList() external;

    function addMOPNPoint(address account, uint256 amount) external;

    function subMOPNPoint(address account, uint256 amount) external;
}
