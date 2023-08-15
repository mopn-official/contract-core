// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./erc6551/interfaces/IMOPNERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNCollectionVault.sol";
import "./libraries/MOPNBitMap.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MOPNData is Multicall {
    using MOPNBitMap for uint256;

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
        uint256 OnMapMOPNPoint;
        uint256 TotalMOPNPoint;
        uint32 tileCoordinate;
    }

    struct CollectionDataOutput {
        address contractAddress;
        address collectionVault;
        uint256 OnMapNum;
        uint256 MTBalance;
        uint256 UnclaimMTBalance;
        uint256 AdditionalMOPNPoints;
        uint256 CollectionMOPNPoints;
        uint256 OnMapMOPNPoints;
        uint256 CollectionMOPNPoint;
        uint256 AdditionalMOPNPoint;
        uint256 PMTTotalSupply;
        IMOPNCollectionVault.NFTAuction NFTAuction;
    }

    IMOPNGovernance public governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function calcPerMOPNPointMinted() public view returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        if (mopn.MTStepStartTimestamp() > block.timestamp) {
            return 0;
        }
        uint256 mData = mopn.getmData();
        if (mData.TotalMOPNPoints() > 0) {
            uint256 lastTickTimestamp = mData.LastTickTimestamp();
            uint256 reduceTimes = mopn.MTReduceTimes();
            if (reduceTimes == 0) {
                mData +=
                    ((block.timestamp - lastTickTimestamp) *
                        mopn.currentMTPPS(reduceTimes)) /
                    mData.TotalMOPNPoints();
            } else {
                uint256 nextReduceTimestamp = mopn.MTStepStartTimestamp() +
                    mopn.MTReduceInterval();
                for (uint256 i = 0; i <= reduceTimes; i++) {
                    mData +=
                        ((nextReduceTimestamp - lastTickTimestamp) *
                            mopn.currentMTPPS(i)) /
                        mData.TotalMOPNPoints();
                    lastTickTimestamp = nextReduceTimestamp;
                    nextReduceTimestamp += mopn.MTReduceInterval();
                    if (nextReduceTimestamp > block.timestamp) {
                        nextReduceTimestamp = block.timestamp;
                    }
                }
            }
        }
        return mData.PerMOPNPointMinted();
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param collectionAddress collection contract address
     */
    function calcCollectionSettledMT(
        address collectionAddress
    ) public view returns (uint256 inbox) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint256 cData = mopn.getcData(collectionAddress);
        inbox = cData.CollectionSettledMT();
        uint256 perMOPNPointMinted = calcPerMOPNPointMinted();

        if (
            cData.CollectionPerMOPNPointMinted() < perMOPNPointMinted &&
            cData.CollectionOnMapMOPNPoints() > 0
        ) {
            inbox +=
                (((perMOPNPointMinted - cData.CollectionPerMOPNPointMinted()) *
                    (cData.CollectionMOPNPoints() +
                        cData.CollectionOnMapMOPNPoints())) * 5) /
                100;
            if (cData.CollectionAdditionalMOPNPoints() > 0) {
                uint256 meData = mopn.getmDataExt();
                if (meData.AdditionalFinishSnapshot() > 0) {
                    inbox +=
                        (((meData.AdditionalFinishSnapshot() -
                            cData.CollectionPerMOPNPointMinted()) *
                            cData.CollectionAdditionalMOPNPoints()) * 5) /
                        100;
                } else {
                    inbox +=
                        (((perMOPNPointMinted -
                            cData.CollectionPerMOPNPointMinted()) *
                            cData.CollectionAdditionalMOPNPoints()) * 5) /
                        100;
                }
            }
        }
    }

    function calcPerCollectionNFTMintedMT(
        address collectionAddress
    ) public view returns (uint256 result) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint256 cData = mopn.getcData(collectionAddress);
        result = cData.PerCollectionNFTMinted();

        uint256 CollectionPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
            cData.CollectionPerMOPNPointMinted();
        if (
            CollectionPerMOPNPointMintedDiff > 0 &&
            cData.CollectionOnMapMOPNPoints() > 0
        ) {
            if (cData.CollectionMOPNPoints() > 0) {
                result += ((CollectionPerMOPNPointMintedDiff *
                    cData.CollectionMOPNPoints()) / cData.CollectionOnMapNum());
            }

            if (cData.CollectionAdditionalMOPNPoints() > 0) {
                uint256 AdditionalFinishSnapshot_ = mopn
                    .getmDataExt()
                    .AdditionalFinishSnapshot();
                if (AdditionalFinishSnapshot_ > 0) {
                    if (
                        AdditionalFinishSnapshot_ >
                        cData.CollectionPerMOPNPointMinted()
                    ) {
                        result += (((AdditionalFinishSnapshot_ -
                            cData.CollectionPerMOPNPointMinted()) *
                            cData.CollectionAdditionalMOPNPoints()) /
                            cData.CollectionOnMapNum());
                    }
                } else {
                    result += (((CollectionPerMOPNPointMintedDiff) *
                        cData.CollectionAdditionalMOPNPoints()) /
                        cData.CollectionOnMapNum());
                }
            }
        }
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param account account wallet address
     */
    function calcAccountMT(
        address account
    ) public view returns (uint256 inbox) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint256 aData = mopn.getaData(account);
        inbox = aData.AccountSettledMT();

        uint256 AccountOnMapMOPNPoint = mopn.getAccountOnMapMOPNPoint(account);

        uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
            aData.AccountPerMOPNPointMinted();

        address collectionAddress = mopn.getAccountCollection(account);

        if (AccountPerMOPNPointMintedDiff > 0 && AccountOnMapMOPNPoint > 0) {
            uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(
                    collectionAddress
                ) - aData.AccountPerCollectionNFTMinted();

            inbox +=
                ((AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) * 90) /
                100;

            if (AccountPerCollectionNFTMintedDiff > 0) {
                inbox += (AccountPerCollectionNFTMintedDiff * 90) / 100;
            }
        }
    }

    function batchsettleAccountMT(address[] memory accounts) public {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint256 mData = mopn.settlePerMOPNPointMinted();
        for (uint256 i = 0; i < accounts.length; i++) {
            address accountCollection = mopn.getAccountCollection(accounts[i]);
            uint256 cData = mopn.settleCollectionMT(accountCollection, mData);
            mopn.settleAccountMT(accounts[i], cData);
        }
    }

    function batchClaimAccountMT(address[] memory accounts) public {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint256 mData = mopn.settlePerMOPNPointMinted();
        uint256 amount;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (
                !IMOPNERC6551Account(payable(accounts[i])).isOwner(msg.sender)
            ) {
                continue;
            }
            address accountCollection = mopn.getAccountCollection(accounts[i]);
            uint256 cData = mopn.settleCollectionMT(accountCollection, mData);
            uint256 aData = mopn.settleAccountMT(accounts[i], cData);

            //todo
        }

        governance.mintMT(msg.sender, amount);
    }

    function getAccountData(
        address account
    ) public view returns (AccountDataOutput memory accountData) {
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
        accountData.OnMapMOPNPoint = IMOPN(governance.mopnContract())
            .getAccountOnMapMOPNPoint(account);
        accountData.TotalMOPNPoint = IERC20(governance.pointContract())
            .balanceOf(account);
        accountData.tileCoordinate = IMOPN(governance.mopnContract())
            .getaData(account)
            .AccountCoordinate();
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
            IERC6551Registry(governance.ERC6551Registry()).account(
                governance.ERC6551AccountProxy(),
                block.chainid,
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
                MOPNBitMap.TileAccount(
                    IMOPN(governance.mopnContract()).gettData(coordinates[i])
                )
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
    function getCollectionData(
        address collectionAddress
    ) public view returns (CollectionDataOutput memory CDO) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        CDO.contractAddress = collectionAddress;
        CDO.collectionVault = governance.getCollectionVault(collectionAddress);

        uint256 cData = mopn.getcData(collectionAddress);

        CDO.OnMapNum = MOPNBitMap.CollectionOnMapNum(cData);
        CDO.MTBalance = IMOPNToken(governance.mtContract()).balanceOf(
            governance.getCollectionVault(collectionAddress)
        );
        CDO.UnclaimMTBalance = calcCollectionSettledMT(collectionAddress);

        CDO.AdditionalMOPNPoints = MOPNBitMap.CollectionAdditionalMOPNPoints(
            cData
        );

        CDO.CollectionMOPNPoints = MOPNBitMap.CollectionMOPNPoints(cData);
        CDO.OnMapMOPNPoints = MOPNBitMap.CollectionOnMapMOPNPoints(cData);
        CDO.CollectionMOPNPoint = mopn.getCollectionMOPNPoint(
            collectionAddress
        );
        CDO.AdditionalMOPNPoint = MOPNBitMap.CollectionAdditionalMOPNPoint(
            cData
        );

        if (CDO.collectionVault != address(0)) {
            CDO.NFTAuction = IMOPNCollectionVault(CDO.collectionVault)
                .getAuctionInfo();
            CDO.PMTTotalSupply = IMOPNCollectionVault(CDO.collectionVault)
                .totalSupply();
        }
    }

    function getCollectionsData(
        address[] memory collectionAddresses
    ) public view returns (CollectionDataOutput[] memory cDatas) {
        cDatas = new CollectionDataOutput[](collectionAddresses.length);
        for (uint256 i = 0; i < collectionAddresses.length; i++) {
            cDatas[i] = getCollectionData(collectionAddresses[i]);
        }
    }

    function getTotalMTStakingRealtime() public view returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint256 mData = mopn.getmData();
        uint256 meData = mopn.getmDataExt();
        return
            (((MOPNBitMap.MTTotalMinted(mData) +
                (calcPerMOPNPointMinted() -
                    MOPNBitMap.PerMOPNPointMinted(mData)) *
                MOPNBitMap.TotalMOPNPoints(mData)) * 5) / 100) -
            MOPNBitMap.TotalCollectionClaimed(meData) +
            MOPNBitMap.TotalMTStaking(meData);
    }
}
