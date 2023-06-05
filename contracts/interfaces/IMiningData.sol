// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMiningData {
    /**
     * add on map mining mopn token allocation weight
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId mopn Land Id
     * @param amount EAW amount
     */
    function addMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) external;

    function subMTAW(uint256 avatarId, uint256 COID, uint32 LandId) external;

    function settlePerMTAWMinted() external;

    function mintAvatarMT(uint256 avatarId) external;

    function claimAvatarSettledIndexMT(
        uint256 avatarId
    ) external returns (uint256 amount);

    function getAvatarInboxMT(
        uint256 avatarId
    ) external view returns (uint256 inbox);

    function getAvatarTotalMinted(
        uint256 avatarId
    ) external view returns (uint256);

    function getAvatarMTAW(uint256 avatarId) external view returns (uint256);

    function getCollectionInboxMT(
        uint256 COID
    ) external view returns (uint256 inbox);

    function getCollectionMTAW(uint256 COID) external view returns (uint256);

    function getCollectionTotalMinted(
        uint256 COID
    ) external view returns (uint256);

    function claimCollectionSettledInboxMT(
        uint256 avatarId,
        uint256 COID
    ) external returns (uint256);

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

    function getLandHolderMTAW(uint32 LandId) external view returns (uint256);

    function mintLandHolderMT(uint32 LandId) external;

    function claimLandHolderSettledIndexMT(
        uint32 LandId
    ) external returns (uint256 amount);

    function calcCollectionMTAW(uint256 COID) external;
}
