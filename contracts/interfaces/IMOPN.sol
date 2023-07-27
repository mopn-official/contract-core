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

    event NFTOfferAccept(
        address indexed collectionAddress,
        uint256 tokenId,
        uint256 price,
        uint256 totalMTStaking,
        uint256 NFTOfferCoefficient
    );

    event NFTAuctionAccept(
        address indexed collectionAddress,
        uint256 tokenId,
        uint256 price
    );

    event VaultStakingChange(
        address collectionAddress,
        address operator,
        bool increase,
        uint256 amount
    );

    event SettleCollectionMOPNPoint(address collectionAddress);

    function getQualifiedAccountCollection(
        address account
    ) external view returns (address, uint256);

    /**
     * @notice an on map avatar move to a new tile
     */
    function moveTo(uint32 tileCoordinate, uint32 LandId) external;

    /**
     * @notice throw a bomb to a tile
     */
    function bomb(uint32 tileCoordinate) external;

    function getTileAccount(
        uint32 tileCoordinate
    ) external view returns (address);

    function getTileLandId(
        uint32 tileCoordinate
    ) external view returns (uint32);

    function MTTotalMinted() external view returns (uint256);

    function PerMOPNPointMinted() external view returns (uint256);

    function TotalMOPNPoints() external view returns (uint256);

    function NFTOfferCoefficient() external view returns (uint256);

    function TotalCollectionClaimed() external view returns (uint256);

    function TotalMTStaking() external view returns (uint256);

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

    function getAccountCoordinate(
        address account
    ) external view returns (uint32);

    function calcAccountMT(
        address account
    ) external view returns (uint256 inbox);

    function settleAccountMT(address account) external returns (uint256);

    function settleAndClaimAccountMT(
        address account
    ) external returns (uint256);

    function claimAccountMT(address account) external returns (uint256);

    function getCollectionMOPNPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAdditionalMOPNPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionOnMapMOPNPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionAdditionalMOPNPoint(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionOnMapNum(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionMOPNPoint(
        address collectionAddress
    ) external view returns (uint256);

    function calcCollectionSettledMT(
        address collectionAddress
    ) external view returns (uint256);

    function settleCollectionMT(address collectionAddress) external;

    function settleCollectionMining(address collectionAddress) external;

    function settleCollectionMOPNPoint(address collectionAddress) external;

    function changeTotalMTStaking(
        address collectionAddress,
        bool increase,
        uint256 amount,
        address operator
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
