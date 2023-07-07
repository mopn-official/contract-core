// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IERC6551Account.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNMap.sol";
import "./interfaces/IMOPNMiningData.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNCollectionVault.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNDataHelper is Ownable {
    struct AccountDataOutput {
        address account;
        address contractAddress;
        uint256 tokenId;
        uint256 BombUsed;
        uint256 MTBalance;
        uint256 NFTPoint;
        uint32 tileCoordinate;
    }

    struct CollectionDataOutput {
        address contractAddress;
        uint256 OnMapNum;
        uint256 AvatarNum;
        uint256 MTBalance;
        uint256 AdditionalNFTPoint;
        uint256 CollectionNFTPoint;
        uint256 AvatarNFTPoint;
        uint256 CollectionPoint;
        uint256 additionalPoint;
        address collectionVault;
        IMOPNCollectionVault.NFTAuction NFTAuction;
    }

    IMOPNGovernance governance;

    constructor(address governanceContract_) {
        governance = IMOPNGovernance(governanceContract_);
    }

    function getAccount(
        address payable account
    ) public view returns (AccountDataOutput memory accountData) {
        IMOPNMiningData miningData = IMOPNMiningData(
            governance.miningDataContract()
        );
        accountData.account = account;
        (, address collectionAddress, uint256 tokenId) = IERC6551Account(
            account
        ).token();

        accountData.tokenId = tokenId;
        accountData.contractAddress = collectionAddress;
        accountData.BombUsed = IMOPNBomb(governance.bombContract()).balanceOf(
            account,
            2
        );
        accountData.MTBalance = IMOPNToken(governance.mtContract()).balanceOf(
            account
        );
        accountData.NFTPoint = IERC20(governance.pointContract()).balanceOf(
            account
        );
        accountData.tileCoordinate = miningData.getAccountCoordinate(account);
    }

    function getAccounts(
        address payable[] memory accounts
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            accountDatas[i] = getAccount(accounts[i]);
        }
    }

    /**
     * @notice get avatar info by nft contractAddress and tokenId
     * @param params  collection contract address and tokenId
     * @return accountData avatar data format struct AvatarDataOutput
     */
    function getAccountByNFT(
        IMOPN.NFTParams calldata params
    ) public view returns (AccountDataOutput memory accountData) {
        accountData = getAccount(
            IMOPN(governance.mopnContract()).getNFTAccount(params)
        );
    }

    /**
     * @notice get avatar infos by nft contractAddresses and tokenIds
     * @param params array of collection contract address and token ids
     * @return accountDatas avatar datas format struct AvatarDataOutput
     */
    function getAccountsByNFTs(
        IMOPN.NFTParams[] calldata params
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            accountDatas[i] = getAccount(
                IMOPN(governance.mopnContract()).getNFTAccount(params[i])
            );
        }
    }

    /**
     * @notice get avatar infos by tile sets start by start coordinate and range by width and height
     * @param startCoordinate start tile coordinate
     * @param width range width
     * @param height range height
     */
    function getAccountsByCoordinateRange(
        uint32 startCoordinate,
        int32 width,
        int32 height
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        uint32 coordinate = startCoordinate;
        uint256 widthabs = SignedMath.abs(width);
        uint256 heightabs = SignedMath.abs(height);
        accountDatas = new AccountDataOutput[](widthabs * heightabs);
        for (uint256 i = 0; i < heightabs; i++) {
            for (uint256 j = 0; j < widthabs; j++) {
                accountDatas[i * widthabs + j] = getAccount(
                    IMOPNMap(governance.mapContract()).getTileAccount(
                        coordinate
                    )
                );
                accountDatas[i * widthabs + j].tileCoordinate = coordinate;
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
    function getAccountsByStartEndCoordinate(
        uint32 startCoordinate,
        uint32 endCoordinate
    ) public view returns (AccountDataOutput[] memory accountDatas) {
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

        return getAccountsByCoordinateRange(startCoordinate, width, height);
    }

    /**
     * @notice get avatars by coordinate array
     * @param coordinates array of coordinates
     * @return accountDatas avatar datas format struct AccountDataOutput
     */
    function getAccountsByCoordinates(
        uint32[] memory coordinates
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](coordinates.length);
        for (uint256 i = 0; i < coordinates.length; i++) {
            accountDatas[i] = getAccount(
                IMOPNMap(governance.mapContract()).getTileAccount(
                    coordinates[i]
                )
            );
            accountDatas[i].tileCoordinate = coordinates[i];
        }
    }

    function getBatchAccountMTBalance(
        address payable[] memory accounts
    ) public view returns (uint256[] memory MTBalances) {
        MTBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            MTBalances[i] = IMOPNToken(governance.mtContract()).balanceOf(
                accounts[i]
            );
        }
    }

    /**
     * get collection contract, on map num, avatar num etc from IGovernance.
     * struct CollectionDataOutput {
        address contractAddress;
        uint256 OnMapNum;
        uint256 AvatarNum;
        uint256 MTBalance;
        uint256 AdditionalNFTPoint;
        uint256 CollectionNFTPoint;
        uint256 AvatarNFTPoint;
        uint256 CollectionPoint;
        uint256 additionalPoint;
        address collectionVault;
        IMOPNCollectionVault.NFTAuction NFTAuction;
    }
     */
    function getCollectionInfo(
        address collectionAddress
    ) public view returns (CollectionDataOutput memory cData) {
        IMOPNMiningData miningData = IMOPNMiningData(
            governance.miningDataContract()
        );
        cData.contractAddress = collectionAddress;
        cData.OnMapNum = miningData.getCollectionOnMapNum(collectionAddress);
        cData.AvatarNum = miningData.getCollectionAvatarNum(collectionAddress);
        cData.MTBalance = IMOPNToken(governance.mtContract()).balanceOf(
            governance.getCollectionVault(collectionAddress)
        );
        cData.AdditionalNFTPoint = miningData.getCollectionAdditionalNFTPoints(
            collectionAddress
        );
        cData.CollectionNFTPoint = miningData.getCollectionNFTPoints(
            collectionAddress
        );
        cData.AvatarNFTPoint = miningData.getCollectionAvatarNFTPoints(
            collectionAddress
        );
        cData.CollectionPoint = miningData.getCollectionPoint(
            collectionAddress
        );
        cData.additionalPoint = miningData.getCollectionAdditionalNFTPoint(
            collectionAddress
        );
        cData.collectionVault = governance.getCollectionVault(
            collectionAddress
        );
        if (cData.collectionVault != address(0)) {
            cData.NFTAuction = IMOPNCollectionVault(cData.collectionVault)
                .getAuctionInfo();
        }
    }

    function getBatchCollectionInfo(
        address[] memory collectionAddresses
    ) public view returns (CollectionDataOutput[] memory cDatas) {
        cDatas = new CollectionDataOutput[](collectionAddresses.length);
        for (uint256 i = 0; i < collectionAddresses.length; i++) {
            cDatas[i] = getCollectionInfo(collectionAddresses[i]);
        }
    }
}
