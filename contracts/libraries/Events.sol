// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library Events {
    /**
     * @notice This event emit when an avatar jump into the map
     * @param account account wallet address
     * @param LandId MOPN Land Id
     * @param tileCoordinate tile coordinate
     */
    event AccountJumpIn(address indexed account, uint16 indexed LandId, uint24 tileCoordinate, address agentPlacer, uint16 AgentAssignPercentage);

    /**
     * @notice This event emit when an avatar move on map
     * @param account account wallet address
     * @param LandId MOPN Land Id
     * @param fromCoordinate tile coordinate
     * @param toCoordinate tile coordinate
     */
    event AccountMove(address indexed account, uint16 indexed LandId, uint24 fromCoordinate, uint24 toCoordinate);

    /**
     * @notice BombUse Event emit when a Bomb is used at a coordinate by an avatar
     * @param account account wallet address
     * @param victim the victim that bombed out of the map
     * @param tileCoordinate the tileCoordinate
     */
    event BombUse(address indexed account, address victim, uint24 tileCoordinate);

    event AccountMTMinted(address indexed account, uint256 amount, uint16 AgentAssignPercentage);

    event CollectionMTMinted(address indexed collectionAddress, uint256 amount);

    event LandHolderMTMinted(uint16 indexed LandId, uint256 amount);

    event CollectionPointChange(address collectionAddress, uint256 CollectionPoint);

    event CollectionVaultCreated(address indexed collectionAddress, address indexed collectionVault);

    event BombSold(address indexed buyer, uint256 amount, uint256 price);

    event ManualClaimGas(address indexed wallet, uint256 amount);
}
