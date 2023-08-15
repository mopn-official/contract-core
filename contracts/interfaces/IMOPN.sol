// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPN {
    /**
     * @notice This event emit when an avatar jump into the map
     * @param account account wallet address
     * @param LandId MOPN Land Id
     * @param tileCoordinate tile coordinate
     */
    event AccountJumpIn(
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
    event AccountMove(
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

    event AccountMTMinted(address indexed account, uint256 amount);

    event CollectionMTMinted(address indexed collectionAddress, uint256 amount);

    event LandHolderMTMinted(uint32 indexed LandId, uint256 amount);

    function MTOutputPerSec() external view returns (uint256);

    function MTStepStartTimestamp() external view returns (uint256);

    function MTReduceInterval() external view returns (uint256);

    function MaxCollectionOnMapNum() external view returns (uint256);

    function MaxCollectionMOPNPoint() external view returns (uint256);

    /**
     * @notice an on map avatar move to a new tile
     */
    function moveTo(uint32 tileCoordinate, uint32 LandId) external;

    /**
     * @notice throw a bomb to a tile
     */
    function bomb(uint32 tileCoordinate) external;

    function gettData(uint32 coordinate) external view returns (uint256);

    function getmData() external view returns (uint256);

    function getmDataExt() external view returns (uint256);

    function getcData(
        address collectionAddress
    ) external view returns (uint256);

    function getaData(address account) external view returns (uint256);

    function currentMTPPS(
        uint256 reduceTimes
    ) external view returns (uint256 MTPPB);

    function currentMTPPS() external view returns (uint256 MTPPB);

    function MTReduceTimes() external view returns (uint256);

    function settlePerMOPNPointMinted() external returns (uint256);

    function accountClaimAvailable(
        address account
    ) external view returns (bool);

    function getAccountCollection(
        address account
    ) external view returns (address collectionAddress);

    function getAccountOnMapMOPNPoint(
        address account
    ) external view returns (uint256);

    function settleAccountMT(
        address account,
        uint256 cData
    ) external returns (uint256);

    function settleAndClaimAccountMT(
        address account
    ) external returns (uint256);

    function getCollectionMOPNPoint(
        address collectionAddress
    ) external view returns (uint256);

    function settleCollectionMT(
        address collectionAddress,
        uint256 mData
    ) external returns (uint256);

    function settleCollectionMining(
        address collectionAddress
    ) external returns (uint256);

    function settleCollectionMOPNPoint(address collectionAddress) external;

    function changeTotalMTStaking(
        address collectionAddress,
        uint256 direction,
        uint256 amount
    ) external;

    function NFTOfferAccept(
        address collectionAddress,
        uint256 price
    ) external returns (uint256, uint256);

    function addMOPNPoint(
        address account,
        address collectionAddress,
        uint256 amount
    ) external;

    function subMOPNPoint(
        address account,
        address collectionAddress,
        uint256 amount
    ) external;
}
