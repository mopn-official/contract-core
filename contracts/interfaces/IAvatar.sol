// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAvatar {
    function getNFTAvatarId(
        address contractAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @notice get avatar collection id
     * @param avatarId avatar Id
     * @return COID colletion id
     */
    function getAvatarCOID(uint256 avatarId) external view returns (uint256);

    function getAvatarTokenId(uint256 avatarId) external view returns (uint256);

    /**
     * @notice get avatar bomb used number
     * @param avatarId avatar Id
     * @return bomb used number
     */
    function getAvatarBombUsed(
        uint256 avatarId
    ) external view returns (uint256);

    /**
     * @notice get avatar on map coordinate
     * @param avatarId avatar Id
     * @return tileCoordinate tile coordinate
     */
    function getAvatarCoordinate(
        uint256 avatarId
    ) external view returns (uint32);

    /**
     * @notice Avatar On Map Action Params
     * @param tileCoordinate destination tile coordinate
     * @param collectionContract the collection contract address of a nft
     * @param tokenId the token Id of a nft
     * @param linkedAvatarId linked same collection avatar Id if you have a collection ally on the map
     * @param LandId the destination tile's LandId
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    struct OnMapParams {
        uint32 tileCoordinate;
        address collectionContract;
        uint256 tokenId;
        uint256 linkedAvatarId;
        uint32 LandId;
        DelegateWallet delegateWallet;
        address vault;
    }

    struct BombParams {
        uint32 tileCoordinate;
        address collectionContract;
        uint256 tokenId;
        DelegateWallet delegateWallet;
        address vault;
    }

    /**
     * @notice Delegate Wallet Protocols
     */
    enum DelegateWallet {
        None,
        DelegateCash,
        Warm
    }

    function ownerOf(
        uint256 avatarId,
        DelegateWallet delegateWallet,
        address vault
    ) external view returns (address);

    /**
     * @notice mint an avatar for a NFT
     * @param collectionContract NFT collection Contract Address
     * @param tokenId NFT tokenId
     * @param proofs NFT collection whitelist proof
     * @param delegateWallet DelegateWallet enum to specify protocol
     * @param vault cold wallet address
     */
    function mintAvatar(
        address collectionContract,
        uint256 tokenId,
        bytes32[] memory proofs,
        DelegateWallet delegateWallet,
        address vault
    ) external;

    /**
     * @notice an off map avatar jump in to the map
     * @param params OnMapParams
     */
    function jumpIn(OnMapParams calldata params) external;

    /**
     * @notice an on map avatar move to a new tile
     * @param params OnMapParams
     */
    function moveTo(OnMapParams calldata params) external;

    /**
     * @notice throw a bomb to a tile
     * @param params BombParams
     */
    function bomb(BombParams calldata params) external;
}
