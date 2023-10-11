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
        uint16 indexed LandId,
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
        uint16 indexed LandId,
        uint32 fromCoordinate,
        uint32 toCoordinate
    );

    /**
     * @notice BombUse Event emit when a Bomb is used at a coordinate by an avatar
     * @param account account wallet address
     * @param victim the victim that bombed out of the map
     * @param tileCoordinate the tileCoordinate
     */
    event BombUse(
        address indexed account,
        address victim,
        uint32 tileCoordinate
    );

    event CollectionPointChange(
        address collectionAddress,
        uint256 CollectionPoint
    );

    event AccountMTMinted(address indexed account, uint256 amount);

    event CollectionMTMinted(address indexed collectionAddress, uint256 amount);

    event LandHolderMTMinted(uint16 indexed LandId, uint256 amount);

    function getQualifiedAccountCollection(
        address account
    ) external view returns (address);

    /**
     * @notice an on map avatar move to a new tile
     */
    function moveTo(
        uint32 tileCoordinate,
        uint16 LandId,
        address[] memory tileAccounts
    ) external;

    function MTOutputPerBlock() external view returns (uint256);

    function MTStepStartBlock() external view returns (uint256);

    function MTReduceInterval() external view returns (uint256);

    function TotalMOPNPoints() external view returns (uint256);

    function LastTickBlock() external view returns (uint256);

    function PerMOPNPointMinted() external view returns (uint256);

    function MTTotalMinted() external view returns (uint256);

    function NFTOfferCoefficient() external view returns (uint256);

    function TotalCollectionClaimed() external view returns (uint256);

    function TotalMTStaking() external view returns (uint256);

    function currentMTPPB() external view returns (uint256);

    function currentMTPPB(uint256 reduceTimes) external view returns (uint256);

    function MTReduceTimes() external view returns (uint256);

    function settlePerMOPNPointMinted() external;

    function getCollectionMOPNPoint(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionMOPNPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionOnMapMOPNPoints(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionOnMapNum(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionPerMOPNPointMinted(
        address collectionAddress
    ) external view returns (uint256);

    function getPerCollectionNFTMinted(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionSettledMT(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionMOPNPointFromStaking(
        address collectionAddress
    ) external view returns (uint48);

    function settleCollectionMT(address collectionAddress) external;

    function claimCollectionMT(
        address collectionAddress
    ) external returns (uint256);

    function settleCollectionMOPNPoint(address collectionAddress) external;

    function accountClaimAvailable(
        address account
    ) external view returns (bool);

    function getAccountCollection(
        address account
    ) external view returns (address collectionAddress);

    function getAccountOnMapMOPNPoint(
        address account
    ) external view returns (uint256);

    function getAccountCoordinate(
        address account
    ) external view returns (uint32);

    function getAccountPerCollectionNFTMinted(
        address account
    ) external view returns (uint256);

    function getAccountPerMOPNPointMinted(
        address account
    ) external view returns (uint256);

    function getAccountSettledMT(
        address account
    ) external view returns (uint256);

    function claimAccountMT(address account, address to) external;

    function changeTotalMTStaking(
        address collectionAddress,
        uint256 direction,
        uint256 amount
    ) external;

    function NFTOfferAccept(
        address collectionAddress,
        uint256 price
    ) external returns (uint256, uint256);
}
