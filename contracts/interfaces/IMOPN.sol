// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPN {
    struct NFTParams {
        address collectionAddress;
        uint256 tokenId;
    }

    event NFTJoin(
        address indexed account,
        address collectionAddress,
        uint256 tokenId
    );

    /**
     * @notice This event emit when an avatar jump into the map
     * @param account account wallet address
     * @param LandId MOPN Land Id
     * @param tileCoordinate tile coordinate
     */
    event NFTJumpIn(
        address indexed account,
        uint32 indexed LandId,
        uint32 tileCoordinate
    );

    /**
     * @notice This event emit when an avatar move on map
     * @param account account wallet address
     * @param LandId MOPN Land Id
     * @param fromCoordinate tile coordinate
     * @param toCoordinate tile coordinate
     */
    event NFTMove(
        address indexed account,
        uint32 indexed LandId,
        uint32 fromCoordinate,
        uint32 toCoordinate
    );

    /**
     * @notice BombUse Event emit when a Bomb is used at a coordinate by an avatar
     * @param account account wallet address
     * @param tileCoordinate the tileCoordinate
     * @param victims the victims that bombed out of the map
     */
    event BombUse(
        address indexed account,
        uint32 tileCoordinate,
        address[] victims,
        uint32[] victimsCoordinates
    );

    function getNFTAccount(
        NFTParams calldata params
    ) external view returns (address);

    /**
     * @notice an on map avatar move to a new tile
     * @param params NFTParams
     */
    function moveTo(
        NFTParams calldata params,
        uint32 tileCoordinate,
        uint32 LandId
    ) external;

    /**
     * @notice throw a bomb to a tile
     * @param params NFTParams
     */
    function bomb(NFTParams calldata params, uint32 tileCoordinate) external;

    function getTileAccount(
        uint32 tileCoordinate
    ) external view returns (address);

    function getTileLandId(
        uint32 tileCoordinate
    ) external view returns (uint32);
}
