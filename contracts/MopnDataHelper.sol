// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./erc6551/interfaces/IERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNData.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNCollectionVault.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNDataHelper is Ownable {
    struct NFTParams {
        address collectionAddress;
        uint256 tokenId;
    }

    struct AccountDataOutput {
        address account;
        address contractAddress;
        uint256 tokenId;
        uint256 BombBadge;
        uint256 MTBalance;
        uint256 MOPNPoint;
        uint32 tileCoordinate;
    }

    struct CollectionDataOutput {
        address contractAddress;
        address collectionVault;
        uint256 OnMapNum;
        uint256 MTBalance;
        uint256 AdditionalMOPNPoints;
        uint256 CollectionMOPNPoints;
        uint256 AvatarMOPNPoints;
        uint256 CollectionMOPNPoint;
        uint256 AdditionalMOPNPoint;
        IMOPNCollectionVault.NFTAuction NFTAuction;
    }

    IMOPNGovernance governance;

    constructor(address governanceContract_) {
        governance = IMOPNGovernance(governanceContract_);
    }

    function getAccountData(
        address account
    ) public view returns (AccountDataOutput memory accountData) {
        IMOPNData miningData = IMOPNData(governance.mopnDataContract());
        accountData.account = account;
        (, address collectionAddress, uint256 tokenId) = IERC6551Account(
            payable(account)
        ).token();

        accountData.tokenId = tokenId;
        accountData.contractAddress = collectionAddress;
        accountData.BombBadge = IMOPNBomb(governance.bombContract()).balanceOf(
            account,
            2
        );
        accountData.MTBalance = IMOPNToken(governance.mtContract()).balanceOf(
            account
        );
        accountData.MOPNPoint = IERC20(governance.pointContract()).balanceOf(
            account
        );
        accountData.tileCoordinate = miningData.getAccountCoordinate(account);
    }

    function getAccountsData(
        address[] memory accounts
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            accountDatas[i] = getAccountData(accounts[i]);
        }
    }

    function getAccountByNFT(
        NFTParams calldata params
    ) public view returns (address) {
        return
            IERC6551Registry(governance.erc6551Registry()).account(
                governance.erc6551AccountImplementation(),
                governance.chainId(),
                params.collectionAddress,
                params.tokenId,
                0
            );
    }

    /**
     * @notice get avatar info by nft contractAddress and tokenId
     * @param params  collection contract address and tokenId
     * @return accountData avatar data format struct AvatarDataOutput
     */
    function getAccountDataByNFT(
        NFTParams calldata params
    ) public view returns (AccountDataOutput memory accountData) {
        accountData = getAccountData(getAccountByNFT(params));
    }

    /**
     * @notice get avatar infos by nft contractAddresses and tokenIds
     * @param params array of collection contract address and token ids
     * @return accountDatas avatar datas format struct AvatarDataOutput
     */
    function getAccountsDataByNFTs(
        NFTParams[] calldata params
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            accountDatas[i] = getAccountData(getAccountByNFT(params[i]));
        }
    }

    /**
     * @notice get avatars by coordinate array
     * @param coordinates array of coordinates
     * @return accountDatas avatar datas format struct AccountDataOutput
     */
    function getAccountsDataByCoordinates(
        uint32[] memory coordinates
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](coordinates.length);
        for (uint256 i = 0; i < coordinates.length; i++) {
            accountDatas[i] = getAccountData(
                IMOPN(governance.mopnContract()).getTileAccount(coordinates[i])
            );
            accountDatas[i].tileCoordinate = coordinates[i];
        }
    }

    function getBatchAccountMTBalance(
        address[] memory accounts
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
     */
    function getCollectionInfo(
        address collectionAddress
    ) public view returns (CollectionDataOutput memory cData) {
        IMOPNData miningData = IMOPNData(governance.mopnDataContract());
        cData.contractAddress = collectionAddress;
        cData.collectionVault = governance.getCollectionVault(
            collectionAddress
        );

        cData.OnMapNum = miningData.getCollectionOnMapNum(collectionAddress);
        cData.MTBalance = IMOPNToken(governance.mtContract()).balanceOf(
            governance.getCollectionVault(collectionAddress)
        );

        cData.AdditionalMOPNPoints = miningData
            .getCollectionAdditionalMOPNPoints(collectionAddress);

        cData.CollectionMOPNPoints = miningData.getCollectionMOPNPoints(
            collectionAddress
        );
        cData.AvatarMOPNPoints = miningData.getCollectionAccountMOPNPoints(
            collectionAddress
        );
        cData.CollectionMOPNPoint = miningData.getCollectionMOPNPoint(
            collectionAddress
        );
        cData.AdditionalMOPNPoint = miningData.getCollectionAdditionalMOPNPoint(
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
