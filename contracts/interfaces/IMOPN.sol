// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPN {
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
     * @param collectionContract the collection contract address of a nft
     * @param tokenId the token Id of a nft
     * @param proofs nft whitelist proofs
     */
    struct WhiteListNFTParams {
        address collectionContract;
        uint256 tokenId;
        bytes32[] proofs;
    }

    struct NFTParams {
        address collectionAddress;
        uint256 tokenId;
    }

    function ownerOf(uint256 avatarId) external view returns (address);

    /**
     * @notice an on map avatar move to a new tile
     * @param params NFTParams
     */
    function moveTo(
        NFTParams calldata params,
        uint32 tileCoordinate,
        uint256 linkedAvatarId,
        uint32 LandId
    ) external;

    /**
     * @notice throw a bomb to a tile
     * @param params NFTParams
     */
    function bomb(NFTParams calldata params, uint32 tileCoordinate) external;

    function getCollectionAdditionalNFTPoints(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionOnMapNum(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionAvatarNum(
        uint256 COID
    ) external view returns (uint256);

    function getCollectionMintedMT(
        uint256 COID
    ) external view returns (uint256);

    function addCollectionMintedMT(uint256 COID, uint256 amount) external;

    function clearCollectionMintedMT(uint256 COID) external;

    function getCollectionContract(
        uint256 COID
    ) external view returns (address);

    function getCollectionCOID(
        address collectionContract
    ) external view returns (uint256);

    function getCollectionsCOIDs(
        address[] memory collectionContracts
    ) external view returns (uint256[] memory COIDs);

    function generateCOID(
        address collectionContract
    ) external returns (uint256);
}
