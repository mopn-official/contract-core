// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IAvatar.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMap.sol";
import "./interfaces/IMiningData.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MopnDataHelper is Ownable {
    struct AvatarDataOutput {
        address contractAddress;
        uint256 tokenId;
        uint256 avatarId;
        uint256 COID;
        uint256 BombUsed;
        uint256 inboxMT;
        uint256 NFTPoint;
        uint32 tileCoordinate;
    }

    struct CollectionDataOutput {
        address contractAddress;
        uint256 COID;
        uint256 OnMapNum;
        uint256 AvatarNum;
        uint256 inboxMT;
        uint256 NFTPoint;
        uint256 AvatarNFTPoint;
    }

    IGovernance governance;

    constructor(address governanceContract_) {
        governance = IGovernance(governanceContract_);
    }

    function getAvatarByAvatarId(
        uint256 avatarId
    ) public view returns (AvatarDataOutput memory avatarData) {
        avatarData.COID = IAvatar(governance.avatarContract()).getAvatarCOID(
            avatarId
        );
        if (avatarData.COID > 0) {
            avatarData.tokenId = IAvatar(governance.avatarContract())
                .getAvatarTokenId(avatarId);
            avatarData.avatarId = avatarId;
            avatarData.contractAddress = governance.getCollectionContract(
                avatarData.COID
            );
            avatarData.BombUsed = IAvatar(governance.avatarContract())
                .getAvatarBombUsed(avatarId);
            avatarData.inboxMT = IMiningData(governance.miningDataContract())
                .calcAvatarMT(avatarId);
            avatarData.NFTPoint = IMiningData(governance.miningDataContract())
                .getAvatarNFTPoint(avatarId);
            avatarData.tileCoordinate = IAvatar(governance.avatarContract())
                .getAvatarCoordinate(avatarId);
        }
    }

    function getAvatarsByAvatarIds(
        uint256[] memory avatarIds
    ) public view returns (AvatarDataOutput[] memory avatarDatas) {
        avatarDatas = new AvatarDataOutput[](avatarIds.length);
        for (uint256 i = 0; i < avatarIds.length; i++) {
            avatarDatas[i] = getAvatarByAvatarId(avatarIds[i]);
        }
    }

    /**
     * @notice get avatar info by nft contractAddress and tokenId
     * @param collection  collection contract address
     * @param tokenId  token Id
     * @return avatarData avatar data format struct AvatarDataOutput
     */
    function getAvatarByNFT(
        address collection,
        uint256 tokenId
    ) public view returns (AvatarDataOutput memory avatarData) {
        avatarData = getAvatarByAvatarId(
            IAvatar(governance.avatarContract()).getNFTAvatarId(
                collection,
                tokenId
            )
        );
    }

    /**
     * @notice get avatar infos by nft contractAddresses and tokenIds
     * @param collections array of collection contract address
     * @param tokenIds array of token Ids
     * @return avatarDatas avatar datas format struct AvatarDataOutput
     */
    function getAvatarsByNFTs(
        address[] calldata collections,
        uint256[] calldata tokenIds
    ) public view returns (AvatarDataOutput[] memory avatarDatas) {
        avatarDatas = new AvatarDataOutput[](collections.length);
        for (uint256 i = 0; i < collections.length; i++) {
            avatarDatas[i] = getAvatarByAvatarId(
                IAvatar(governance.avatarContract()).getNFTAvatarId(
                    collections[i],
                    tokenIds[i]
                )
            );
        }
    }

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
    ) public view returns (AvatarDataOutput[] memory avatarDatas) {
        uint32 coordinate = startCoordinate;
        uint256 widthabs = SignedMath.abs(width);
        uint256 heightabs = SignedMath.abs(height);
        avatarDatas = new AvatarDataOutput[](widthabs * heightabs);
        for (uint256 i = 0; i < heightabs; i++) {
            for (uint256 j = 0; j < widthabs; j++) {
                avatarDatas[i * widthabs + j] = getAvatarByAvatarId(
                    IMap(governance.mapContract()).getTileAvatar(coordinate)
                );
                avatarDatas[i * widthabs + j].tileCoordinate = coordinate;
                coordinate = width > 0
                    ? TileMath.neighbor(coordinate, (j % 2 == 0 ? 5 : 0))
                    : TileMath.neighbor(coordinate, (j % 2 == 0 ? 3 : 2));
            }
            startCoordinate = TileMath.neighbor(
                startCoordinate,
                height > 0 ? 1 : 4
            );
            coordinate = startCoordinate;
        }
    }

    /**
     * @notice get avatar infos by tile sets start by start coordinate and end by end coordinates
     * @param startCoordinate start tile coordinate
     * @param endCoordinate end tile coordinate
     */
    function getAvatarsByStartEndCoordinate(
        uint32 startCoordinate,
        uint32 endCoordinate
    ) public view returns (AvatarDataOutput[] memory avatarDatas) {
        TileMath.XYCoordinate memory startxy = TileMath.coordinateToXY(
            startCoordinate
        );
        TileMath.XYCoordinate memory endxy = TileMath.coordinateToXY(
            endCoordinate
        );
        int32 width = endxy.x - startxy.x;
        int32 height;
        if (width > 0) {
            height = startxy.y - (width / 2) - endxy.y;
            width += 1;
        } else {
            height = startxy.y + (width / 2) - endxy.y;
            width -= 1;
        }

        return getAvatarsByCoordinateRange(startCoordinate, width, height);
    }

    /**
     * @notice get avatars by coordinate array
     * @param coordinates array of coordinates
     * @return avatarDatas avatar datas format struct AvatarDataOutput
     */
    function getAvatarsByCoordinates(
        uint32[] memory coordinates
    ) public view returns (AvatarDataOutput[] memory avatarDatas) {
        avatarDatas = new AvatarDataOutput[](coordinates.length);
        for (uint256 i = 0; i < coordinates.length; i++) {
            avatarDatas[i] = getAvatarByAvatarId(
                IMap(governance.mapContract()).getTileAvatar(coordinates[i])
            );
            avatarDatas[i].tileCoordinate = coordinates[i];
        }
    }

    function getBatchAvatarInboxMT(
        uint256[] memory avatarIds
    ) public view returns (uint256[] memory inboxMTs) {
        inboxMTs = new uint256[](avatarIds.length);
        for (uint256 i = 0; i < avatarIds.length; i++) {
            inboxMTs[i] = IMiningData(governance.miningDataContract())
                .calcAvatarMT(avatarIds[i]);
        }
    }

    /**
     * get collection contract, on map num, avatar num etc from IGovernance.
     */
    function getCollectionInfo(
        uint256 COID
    ) public view returns (CollectionDataOutput memory cData) {
        cData.contractAddress = governance.getCollectionContract(COID);
        cData.COID = COID;
        cData.OnMapNum = governance.getCollectionOnMapNum(COID);
        cData.AvatarNum = governance.getCollectionAvatarNum(COID);
        cData.inboxMT = IMiningData(governance.miningDataContract())
            .calcCollectionMT(COID);
        cData.NFTPoint = IMiningData(governance.miningDataContract())
            .getCollectionNFTPoint(COID);
        cData.AvatarNFTPoint = IMiningData(governance.miningDataContract())
            .getCollectionAvatarNFTPoint(COID);
    }

    function getBatchCollectionInfo(
        uint256[] memory COIDs
    ) public view returns (CollectionDataOutput[] memory cDatas) {
        cDatas = new CollectionDataOutput[](COIDs.length);
        for (uint256 i = 0; i < COIDs.length; i++) {
            cDatas[i] = getCollectionInfo(COIDs[i]);
        }
    }
}
