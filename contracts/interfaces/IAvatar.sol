// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAvatar {
    struct AvatarDataOutput {
        address contractAddress;
        uint256 tokenId;
        uint256 COID;
        uint256 BombUsed;
        uint32 tileCoordinate;
    }

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
     * @notice get avatar info by avatarId
     * @param avatarId avatar Id
     * @return avatarData avatar data format struct AvatarDataOutput
     */
    function getAvatarByAvatarId(
        uint256 avatarId
    ) external view returns (AvatarDataOutput memory avatarData);

    /**
     * @notice get avatar info by nft contractAddress and tokenId
     * @param collection  collection contract address
     * @param tokenId  token Id
     * @return avatarData avatar data format struct AvatarDataOutput
     */
    function getAvatarByNFT(
        address collection,
        uint256 tokenId
    ) external view returns (AvatarDataOutput memory avatarData);

    /**
     * @notice get avatar infos by nft contractAddresses and tokenIds
     * @param collections array of collection contract address
     * @param tokenIds array of token Ids
     * @return avatarDatas avatar datas format struct AvatarDataOutput
     */
    function getAvatarsByNFTs(
        address[] memory collections,
        uint256[] memory tokenIds
    ) external view returns (AvatarDataOutput[] memory avatarDatas);

    /**
     * @notice get avatar infos by tile sets start by start coordinate and range by width and height
     * @param startCoordinate start tile coordinate
     * @param width range width
     * @param height range height
     */
    function getAvatarsByCoordinateRange(
        uint32 startCoordinate,
        int32 width,
        int32 height
    ) external view returns (AvatarDataOutput[] memory avatarDatas);

    /**
     * @notice get avatar infos by tile sets start by start coordinate and end by end coordinates
     * @param startCoordinate start tile coordinate
     * @param endCoordinate end tile coordinate
     */
    function getAvatarsByStartEndCoordinate(
        uint32 startCoordinate,
        uint32 endCoordinate
    ) external view returns (AvatarDataOutput[] memory avatarDatas);

    /**
     * @notice get avatars by coordinate array
     * @param coordinates array of token Ids
     * @return avatarDatas avatar datas format struct AvatarDataOutput
     */
    function getAvatarsByCoordinates(
        uint32[] memory coordinates
    ) external view returns (AvatarDataOutput[] memory avatarDatas);

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
