// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMap {
    function avatarSet(
        uint256 avatarId,
        uint256 COID,
        uint32 tileCoordinate,
        uint32 LandId,
        uint256 BombUsed
    ) external;

    function avatarRemove(
        uint32 tileCoordinate,
        uint256 excludeAvatarId
    ) external returns (uint256);

    function getTileAvatar(
        uint32 tileCoordinate
    ) external view returns (uint256);

    function getTileCOID(uint32 tileCoordinate) external view returns (uint256);

    function getTileLandId(
        uint32 tileCoordinate
    ) external view returns (uint32);

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

    function redeemCollectionInboxMT(uint256 avatarId, uint256 COID) external;

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

    function transferOwnership(address newOwner) external;
}
