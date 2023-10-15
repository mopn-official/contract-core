// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPN {
    struct CollectionDataStruct {
        uint48 CollectionMOPNPoint;
        uint48 OnMapMOPNPoints;
        uint16 OnMapNftNumber;
        uint48 PerCollectionNFTMinted;
        uint48 PerMOPNPointMinted;
        uint48 SettledMT;
    }

    struct AccountDataStruct {
        uint16 LandId;
        uint32 Coordinate;
        uint48 PerCollectionNFTMinted;
        uint48 PerMOPNPointMinted;
        uint48 SettledMT;
        uint48 NFTOWnerSettledMT;
    }

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

    /**
     * @notice an on map avatar move to a new tile
     */
    function moveTo(
        uint32 tileCoordinate,
        uint16 LandId,
        address[] memory tileAccounts
    ) external;

    function MTOutputPerBlock() external view returns (uint32);

    function MTStepStartBlock() external view returns (uint32);

    function MTReduceInterval() external view returns (uint256);

    function TotalMOPNPoints() external view returns (uint48);

    function LastTickBlock() external view returns (uint32);

    function PerMOPNPointMinted() external view returns (uint48);

    function MTTotalMinted() external view returns (uint64);

    function NFTOfferCoefficient() external view returns (uint48);

    function TotalCollectionClaimed() external view returns (uint48);

    function TotalMTStaking() external view returns (uint64);

    function currentMTPPB() external view returns (uint256);

    function currentMTPPB(uint256 reduceTimes) external view returns (uint256);

    function MTReduceTimes() external view returns (uint256);

    function settlePerMOPNPointMinted() external;

    function getCollectionData(
        address collectionAddress
    ) external view returns (CollectionDataStruct memory);

    function getCollectionMOPNPointFromStaking(
        address collectionAddress
    ) external view returns (uint48);

    function settleCollectionMT(address collectionAddress) external;

    function claimCollectionMT(address collectionAddress) external;

    function settleCollectionMOPNPoint(address collectionAddress) external;

    function accountClaimAvailable(
        address account
    ) external view returns (bool);

    function getAccountData(
        address account
    ) external view returns (AccountDataStruct memory);

    function getAccountCollection(
        address account
    ) external view returns (address collectionAddress);

    function getAccountOnMapMOPNPoint(
        address account
    ) external view returns (uint256 OnMapMOPNPoint);

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
