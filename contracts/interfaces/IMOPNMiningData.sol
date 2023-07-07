// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPNMiningData {
    function getNFTOfferCoefficient() external view returns (uint256);

    function getTotalNFTPoints() external view returns (uint256);

    function addNFTPoint(address payable account, uint256 amount) external;

    function subNFTPoint(address payable account) external;

    function settlePerNFTPointMinted() external;

    function getAccountTotalNFTPoint(
        address account
    ) external view returns (uint256);

    function getAccountPerNFTPointMinted(
        address payable account
    ) external view returns (uint256);

    function getAccountCoordinate(
        address payable account
    ) external view returns (uint32);

    function setAccountCoordinate(
        address payable account,
        uint32 coordinate
    ) external;

    function calcAccountMT(
        address payable account
    ) external view returns (uint256 inbox);

    function mintAccountMT(address payable account) external returns (uint256);

    function claimAccountMT(address payable account, address to) external;

    function getCollectionNFTPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAdditionalNFTPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAvatarNFTPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAdditionalNFTPoint(
        address collectionAddress
    ) external view returns (uint256);

    function setCollectionAdditionalNFTPoint(
        address collectionAddress,
        uint256 additionalNFTPoint
    ) external;

    function getCollectionOnMapNum(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAvatarNum(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionPoint(
        address collectionAddress
    ) external view returns (uint256);

    function calcCollectionMT(
        address collectionAddress
    ) external view returns (uint256);

    function mintCollectionMT(address collectionAddress) external;

    function claimCollectionMT(address collectionAddressD) external;

    function settleCollectionMining(address collectionAddress) external;

    function settleCollectionNFTPoint(address collectionAddress) external;

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
}
