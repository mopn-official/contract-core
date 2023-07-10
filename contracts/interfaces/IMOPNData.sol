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

    event SettleCollectionNFTPoint(address collectionAddress);

    function getNFTOfferCoefficient() external view returns (uint256);

    function getTotalNFTPoints() external view returns (uint256);

    function addNFTPoint(address account, uint256 amount) external;

    function subNFTPoint(address account, uint256 amount) external;

    function settlePerNFTPointMinted() external;

    function getAccountCollection(
        address account
    ) external view returns (address collectionAddress);

    function checkNFTAccount(
        address account
    ) external view returns (bool exist);

    function initNFTAccount(address account) external;

    function getAccountTotalNFTPoint(
        address account
    ) external view returns (uint256);

    function getAccountPerNFTPointMinted(
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

    function claimAccountMT(address account, address to) external;

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
