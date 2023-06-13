// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAvatar.sol";

interface IMiningData {
    function getNFTOfferCoefficient() external view returns (uint256);

    /**
     * add on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param amount EAW amount
     */
    function addNFTPoint(
        uint256 avatarId,
        uint256 COID,
        uint256 amount
    ) external;

    function subNFTPoint(uint256 avatarId, uint256 COID) external;

    function settlePerNFTPointMinted() external;

    function getAvatarNFTPoint(
        uint256 avatarId
    ) external view returns (uint256);

    function calcAvatarMT(
        uint256 avatarId
    ) external view returns (uint256 inbox);

    function mintAvatarMT(uint256 avatarId) external returns (uint256);

    function redeemAvatarMT(
        uint256 avatarId,
        IAvatar.DelegateWallet delegateWallet,
        address vault
    ) external;

    function getCollectionNFTPoint(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionAvatarNFTPoint(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionPoint(uint256 COID) external view returns (uint256);

    function calcCollectionMT(uint256 COID) external view returns (uint256);

    function mintCollectionMT(uint256 COID) external;

    function redeemCollectionMT(uint256 COID) external;

    function settleCollectionMining(uint256 COID) external;

    function settleCollectionNFTPoint(uint256 COID) external;

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
        uint256 COID,
        bool increase,
        uint256 amount
    ) external;

    function NFTOfferAcceptNotify(uint256 price) external;
}
