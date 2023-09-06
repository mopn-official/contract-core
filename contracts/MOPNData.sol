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
import "./libraries/TileMath.sol";
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

    function calcPerMOPNPointMinted() public view returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        if (mopn.MTStepStartBlock() > block.number) {
            return 0;
        }
        uint256 totalMOPNPoints = mopn.TotalMOPNPoints();
        uint256 perMOPNPointMinted = mopn.PerMOPNPointMinted();
        if (totalMOPNPoints > 0) {
            uint256 lastTickBlock = mopn.LastTickBlock();
            uint256 reduceTimes = mopn.MTReduceTimes();
            if (reduceTimes == 0) {
                perMOPNPointMinted +=
                    ((block.number - lastTickBlock) * mopn.MTOutputPerBlock()) /
                    totalMOPNPoints;
            } else {
                uint256 nextReduceBlock = mopn.MTStepStartBlock() +
                    mopn.MTReduceInterval();
                for (uint256 i = 0; i <= reduceTimes; i++) {
                    perMOPNPointMinted +=
                        ((nextReduceBlock - lastTickBlock) *
                            mopn.currentMTPPB(i)) /
                        totalMOPNPoints;
                    lastTickBlock = nextReduceBlock;
                    nextReduceBlock += mopn.MTReduceInterval();
                    if (nextReduceBlock > block.number) {
                        nextReduceBlock = block.number;
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
        uint256 AdditionalFinishSnapshot = mopn.AdditionalFinishSnapshot();

        if (
            CollectionPerMOPNPointMinted < perMOPNPointMinted &&
            OnMapMOPNPoints > 0
        ) {
            if (AdditionalMOPNPoints > 0 && AdditionalFinishSnapshot > 0) {
                inbox +=
                    (((perMOPNPointMinted - CollectionPerMOPNPointMinted) *
                        (CollectionMOPNPoints -
                            AdditionalMOPNPoints +
                            OnMapMOPNPoints)) * 5) /
                    100;
                inbox +=
                    (((AdditionalFinishSnapshot -
                        CollectionPerMOPNPointMinted) * AdditionalMOPNPoints) *
                        5) /
                    100;
            } else {
                inbox +=
                    (((perMOPNPointMinted - CollectionPerMOPNPointMinted) *
                        (CollectionMOPNPoints + OnMapMOPNPoints)) * 5) /
                    100;
            }
        }
    }

    function calcPerCollectionNFTMintedMT(
        address collectionAddress
    ) public view returns (uint256 result) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        result = mopn.getPerCollectionNFTMinted(collectionAddress);

        uint256 CollectionMOPNPoints = mopn.getCollectionMOPNPoints(
            collectionAddress
        );

        if (CollectionMOPNPoints > 0) {
            uint256 CollectionPerMOPNPointMinted = mopn
                .getCollectionPerMOPNPointMinted(collectionAddress);
            uint256 PerMOPNPointMinted = calcPerMOPNPointMinted();
            uint256 AdditionalMOPNPoints = mopn
                .getCollectionAdditionalMOPNPoints(collectionAddress);
            uint256 AdditionalFinishSnapshot = mopn.AdditionalFinishSnapshot();

            if (AdditionalMOPNPoints > 0 && AdditionalFinishSnapshot > 0) {
                result +=
                    ((PerMOPNPointMinted - CollectionPerMOPNPointMinted) *
                        (CollectionMOPNPoints - AdditionalMOPNPoints)) /
                    mopn.getCollectionOnMapNum(collectionAddress);
                result +=
                    ((AdditionalFinishSnapshot - CollectionPerMOPNPointMinted) *
                        AdditionalMOPNPoints) /
                    mopn.getCollectionOnMapNum(collectionAddress);
            } else {
                result +=
                    ((PerMOPNPointMinted - CollectionPerMOPNPointMinted) *
                        CollectionMOPNPoints) /
                    mopn.getCollectionOnMapNum(collectionAddress);
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

        if (AccountPerMOPNPointMintedDiff > 0 && AccountOnMapMOPNPoint > 0) {
            inbox +=
                ((AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) * 90) /
                100;
            uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(
                    mopn.getAccountCollection(account)
                ) - mopn.getAccountPerCollectionNFTMinted(account);

            if (AccountPerCollectionNFTMintedDiff > 0) {
                inbox += (AccountPerCollectionNFTMintedDiff * 90) / 100;
            }
        }
    }

    function calcLandsMT(
        uint32[] memory LandIds,
        address[][] memory tileAccounts
    ) public view returns (uint256[] memory amounts) {
        amounts = new uint256[](LandIds.length);
        for (uint256 i = 0; i < LandIds.length; i++) {
            amounts[i] = calcLandMT(LandIds[i], tileAccounts[i]);
        }
    }

    function calcLandMT(
        uint32 LandId,
        address[] memory tileAccounts
    ) public view returns (uint256 amount) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint32 tileCoordinate = TileMath.LandCenterTile(LandId);
        for (uint256 i; i < tileAccounts.length; i++) {
            if (
                TileMath.distance(
                    tileCoordinate,
                    mopn.getAccountCoordinate(tileAccounts[i])
                ) < 6
            ) {
                amount += calcLandAccountMT(tileAccounts[i]);
            }
        }
    }

    function calcLandAccountMT(
        address account
    ) public view returns (uint256 amount) {
        if (account != address(0)) {
            IMOPN mopn = IMOPN(governance.mopnContract());
            uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
                mopn.getAccountPerMOPNPointMinted(account);

            if (AccountPerMOPNPointMintedDiff > 0) {
                address collectionAddress = mopn.getAccountCollection(account);
                uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(
                        collectionAddress
                    ) - mopn.getAccountPerCollectionNFTMinted(account);
                uint256 AccountOnMapMOPNPoint = mopn.getAccountOnMapMOPNPoint(
                    account
                );
                amount +=
                    ((AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) *
                        5) /
                    100;
                if (AccountPerCollectionNFTMintedDiff > 0) {
                    amount += (AccountPerCollectionNFTMintedDiff * 5) / 100;
                }
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

        cData.OnMapMOPNPoints = mopn.getCollectionOnMapMOPNPoints(
            collectionAddress
        );
        cData.CollectionMOPNPoint = mopn.getCollectionMOPNPointFromStaking(
            collectionAddress
        );
        cData.CollectionMOPNPoints = cData.CollectionMOPNPoint * cData.OnMapNum;
        cData.AdditionalMOPNPoint = mopn.getCollectionAdditionalMOPNPoint(
            collectionAddress
        );
        cData.AdditionalMOPNPoints = mopn.getCollectionAdditionalMOPNPoints(
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
