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
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MOPNData is Multicall {
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

    function batchsettleAccountMT(address[] memory accounts) public {
        IMOPN mopn = IMOPN(governance.mopnContract());
        mopn.settlePerMOPNPointMinted();
        for (uint256 i = 0; i < accounts.length; i++) {
            address accountCollection = mopn.getAccountCollection(accounts[i]);
            mopn.settleCollectionMT(accountCollection);
            mopn.settleAccountMT(accounts[i], accountCollection);
        }
    }

    function batchClaimAccountMT(address[][] memory accounts) public {
        IMOPN mopn = IMOPN(governance.mopnContract());
        mopn.settlePerMOPNPointMinted();
        uint256 amount;
        address collectionAddress;
        for (uint256 i = 0; i < accounts.length; i++) {
            collectionAddress = address(0);
            for (uint256 k = 0; k < accounts[i].length; k++) {
                if (
                    !IMOPNERC6551Account(payable(accounts[i][k])).isOwner(
                        msg.sender
                    )
                ) {
                    continue;
                }

                if (collectionAddress == address(0)) {
                    collectionAddress = mopn.getAccountCollection(
                        accounts[i][k]
                    );
                    mopn.settleCollectionMT(collectionAddress);
                }

                mopn.settleAccountMT(accounts[i][k], collectionAddress);
                amount += mopn.claimAccountMT(accounts[i][k]);
            }
        }
        governance.mintMT(msg.sender, amount);
    }

    function calcPerMOPNPointMinted() public view returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        if (mopn.MTStepStartTimestamp() > block.timestamp) {
            return 0;
        }
        uint256 totalMOPNPoints = mopn.TotalMOPNPoints();
        uint256 perMOPNPointMinted = mopn.PerMOPNPointMinted();
        if (totalMOPNPoints > 0) {
            uint256 lastTickTimestamp = mopn.LastTickTimestamp();
            uint256 reduceTimes = mopn.MTReduceTimes();
            if (reduceTimes == 0) {
                perMOPNPointMinted +=
                    ((block.timestamp - lastTickTimestamp) *
                        mopn.MTOutputPerSec()) /
                    totalMOPNPoints;
            } else {
                uint256 nextReduceTimestamp = mopn.MTStepStartTimestamp() +
                    mopn.MTReduceInterval();
                for (uint256 i = 0; i <= reduceTimes; i++) {
                    perMOPNPointMinted +=
                        ((nextReduceTimestamp - lastTickTimestamp) *
                            mopn.currentMTPPS(i)) /
                        totalMOPNPoints;
                    lastTickTimestamp = nextReduceTimestamp;
                    nextReduceTimestamp += mopn.MTReduceInterval();
                    if (nextReduceTimestamp > block.timestamp) {
                        nextReduceTimestamp = block.timestamp;
                    }
                }
            }
        }
        return perMOPNPointMinted;
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param collectionAddress collection contract address
     */
    function calcCollectionSettledMT(
        address collectionAddress
    ) public view returns (uint256 inbox) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        inbox = mopn.getCollectionSettledMT(collectionAddress);
        uint256 perMOPNPointMinted = calcPerMOPNPointMinted();
        uint256 CollectionPerMOPNPointMinted = mopn
            .getCollectionPerMOPNPointMinted(collectionAddress);
        uint256 AdditionalMOPNPoints = mopn.getCollectionAdditionalMOPNPoints(
            collectionAddress
        );
        uint256 CollectionMOPNPoints = mopn.getCollectionMOPNPoints(
            collectionAddress
        );
        uint256 OnMapMOPNPoints = mopn.getCollectionOnMapMOPNPoints(
            collectionAddress
        );

        if (
            CollectionPerMOPNPointMinted < perMOPNPointMinted &&
            OnMapMOPNPoints > 0
        ) {
            inbox +=
                (((perMOPNPointMinted - CollectionPerMOPNPointMinted) *
                    (CollectionMOPNPoints + OnMapMOPNPoints)) * 5) /
                100;
            if (AdditionalMOPNPoints > 0) {
                if (mopn.AdditionalFinishSnapshot() > 0) {
                    inbox +=
                        (((mopn.AdditionalFinishSnapshot() -
                            CollectionPerMOPNPointMinted) *
                            AdditionalMOPNPoints) * 5) /
                        100;
                } else {
                    inbox +=
                        (((perMOPNPointMinted - CollectionPerMOPNPointMinted) *
                            AdditionalMOPNPoints) * 5) /
                        100;
                }
            }
        }
    }

    function calcPerCollectionNFTMintedMT(
        address collectionAddress
    ) public view returns (uint256 result) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        result = mopn.getPerCollectionNFTMinted(collectionAddress);

        uint256 CollectionPerMOPNPointMinted = mopn
            .getCollectionPerMOPNPointMinted(collectionAddress);
        uint256 CollectionPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
            CollectionPerMOPNPointMinted;
        if (
            CollectionPerMOPNPointMintedDiff > 0 &&
            mopn.getCollectionOnMapMOPNPoints(collectionAddress) > 0
        ) {
            uint256 CollectionMOPNPoints = mopn.getCollectionMOPNPoints(
                collectionAddress
            );

            if (CollectionMOPNPoints > 0) {
                result += ((CollectionPerMOPNPointMintedDiff *
                    CollectionMOPNPoints) /
                    mopn.getCollectionOnMapNum(collectionAddress));
            }

            uint256 AdditionalMOPNPoints = mopn
                .getCollectionAdditionalMOPNPoints(collectionAddress);
            if (AdditionalMOPNPoints > 0) {
                uint256 AdditionalFinishSnapshot_ = mopn
                    .AdditionalFinishSnapshot();
                if (AdditionalFinishSnapshot_ > 0) {
                    if (
                        AdditionalFinishSnapshot_ > CollectionPerMOPNPointMinted
                    ) {
                        result += (((AdditionalFinishSnapshot_ -
                            CollectionPerMOPNPointMinted) *
                            AdditionalMOPNPoints) /
                            mopn.getCollectionOnMapNum(collectionAddress));
                    }
                } else {
                    result += (((CollectionPerMOPNPointMintedDiff) *
                        AdditionalMOPNPoints) /
                        mopn.getCollectionOnMapNum(collectionAddress));
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
        inbox = mopn.getAccountSettledMT(account);
        uint256 AccountOnMapMOPNPoint = mopn.getAccountOnMapMOPNPoint(account);
        uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
            mopn.getAccountPerMOPNPointMinted(account);

        address collectionAddress = mopn.getAccountCollection(account);
        if (AccountPerMOPNPointMintedDiff > 0 && AccountOnMapMOPNPoint > 0) {
            uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(
                    collectionAddress
                ) - mopn.getAccountPerCollectionNFTMinted(account);
            inbox +=
                ((AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) * 90) /
                100;
            if (AccountPerCollectionNFTMintedDiff > 0) {
                inbox += (AccountPerCollectionNFTMintedDiff * 90) / 100;
            }
        }
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
            .getAccountCoordinate(account);
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
    function getCollectionData(
        address collectionAddress
    ) public view returns (CollectionDataOutput memory cData) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        cData.contractAddress = collectionAddress;
        cData.collectionVault = governance.getCollectionVault(
            collectionAddress
        );

        cData.OnMapNum = mopn.getCollectionOnMapNum(collectionAddress);
        cData.MTBalance = IMOPNToken(governance.mtContract()).balanceOf(
            governance.getCollectionVault(collectionAddress)
        );
        cData.UnclaimMTBalance = calcCollectionSettledMT(collectionAddress);

        cData.AdditionalMOPNPoints = mopn.getCollectionAdditionalMOPNPoints(
            collectionAddress
        );

        cData.CollectionMOPNPoints = mopn.getCollectionMOPNPoints(
            collectionAddress
        );
        cData.OnMapMOPNPoints = mopn.getCollectionOnMapMOPNPoints(
            collectionAddress
        );
        cData.CollectionMOPNPoint = mopn.getCollectionMOPNPoint(
            collectionAddress
        );
        cData.AdditionalMOPNPoint = mopn.getCollectionAdditionalMOPNPoint(
            collectionAddress
        );

        if (cData.collectionVault != address(0)) {
            cData.NFTAuction = IMOPNCollectionVault(cData.collectionVault)
                .getAuctionInfo();
            cData.PMTTotalSupply = IMOPNCollectionVault(cData.collectionVault)
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
        return
            (((mopn.MTTotalMinted() +
                (calcPerMOPNPointMinted() - mopn.PerMOPNPointMinted()) *
                mopn.TotalMOPNPoints()) * 5) / 100) -
            mopn.TotalCollectionClaimed() +
            mopn.TotalMTStaking();
    }
}
