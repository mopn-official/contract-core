// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "hardhat/console.sol";

import {MOPNBase, NFTParams, AccountDataOutput, CollectionDataOutput} from "../libraries/LibMOPN.sol";
import {Constants} from "contracts/libraries/Constants.sol";
import {Errors} from "contracts/libraries/Errors.sol";
import {Events} from "contracts/libraries/Events.sol";
import "../erc6551/interfaces/IMOPNERC6551Account.sol";
import "../erc6551/interfaces/IERC6551Registry.sol";
import "../interfaces/IMOPNCollectionVault.sol";
import "../interfaces/IMOPNBomb.sol";
import "../interfaces/IMOPNToken.sol";
import "../interfaces/IMOPNLand.sol";

contract MOPNDataFacet is MOPNBase {
    function MTTotalMinted() public view returns (uint256) {
        return s.MTTotalMinted;
    }

    function TotalMOPNPoints() public view returns (uint256) {
        return s.TotalMOPNPoints;
    }

    function PerMOPNPointMinted() public view returns (uint256) {
        return s.PerMOPNPointMinted;
    }

    function tokenContract() public view returns (address) {
        return s.tokenContract;
    }

    function landContract() public view returns (address) {
        return s.landContract;
    }

    function ERC6551AccountHelper() public view returns (address) {
        return s.ERC6551AccountHelper;
    }

    function ERC6551AccountProxy() public view returns (address) {
        return s.ERC6551AccountProxy;
    }

    function currentMTPPB() public view returns (uint256 MTPPB) {
        if (s.MTStepStartTimestamp > block.timestamp) {
            return 0;
        }
        return currentMTPPB(MTReduceTimes());
    }

    function calcPerMOPNPointMinted() public view returns (uint256) {
        if (s.MTStepStartTimestamp > block.timestamp) {
            return 0;
        }
        uint256 perMOPNPointMinted = s.PerMOPNPointMinted;
        if (s.TotalMOPNPoints > 0) {
            uint256 lastTickTimestamp = s.LastTickTimestamp;
            uint256 reduceTimes = MTReduceTimes();
            if (reduceTimes == 0) {
                perMOPNPointMinted += ((block.timestamp - lastTickTimestamp) * s.MTOutputPerTimestamp) / s.TotalMOPNPoints;
            } else {
                uint256 nextReduceTimestamp = s.MTStepStartTimestamp + Constants.MTReduceInterval;
                for (uint256 i = 0; i <= reduceTimes; i++) {
                    perMOPNPointMinted += ((nextReduceTimestamp - lastTickTimestamp) * currentMTPPB(i)) / s.TotalMOPNPoints;
                    lastTickTimestamp = nextReduceTimestamp;
                    nextReduceTimestamp += Constants.MTReduceInterval;
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
    function calcCollectionSettledMT(address collectionAddress) public view returns (uint256 inbox) {
        inbox = s.CDs[collectionAddress].SettledMT;
        uint256 perMOPNPointMinted = calcPerMOPNPointMinted();
        uint256 CollectionPerMOPNPointMinted = s.CDs[collectionAddress].PerMOPNPointMinted;
        uint256 CollectionMOPNPoints = s.CDs[collectionAddress].CollectionMOPNPoint * s.CDs[collectionAddress].OnMapNftNumber;
        uint256 OnMapMOPNPoints = s.CDs[collectionAddress].OnMapMOPNPoints;

        if (CollectionPerMOPNPointMinted < perMOPNPointMinted && OnMapMOPNPoints > 0) {
            inbox += (((perMOPNPointMinted - CollectionPerMOPNPointMinted) * (CollectionMOPNPoints + OnMapMOPNPoints)) * 5) / 100;
        }
    }

    function calcPerCollectionNFTMintedMT(address collectionAddress) public view returns (uint256 result) {
        result = s.CDs[collectionAddress].PerCollectionNFTMinted;

        uint256 CollectionMOPNPoints = s.CDs[collectionAddress].CollectionMOPNPoint * s.CDs[collectionAddress].OnMapNftNumber;

        if (CollectionMOPNPoints > 0) {
            uint256 CollectionPerMOPNPointMinted = s.CDs[collectionAddress].PerMOPNPointMinted;
            uint256 perMOPNPointMinted = calcPerMOPNPointMinted();

            result += ((perMOPNPointMinted - CollectionPerMOPNPointMinted) * CollectionMOPNPoints) / s.CDs[collectionAddress].OnMapNftNumber;
        }
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param account account wallet address
     */
    function calcAccountMT(address account) public view returns (uint256 inbox) {
        inbox = s.ADs[account].SettledMT;
        uint256 AccountOnMapMOPNPoint = tilepoint(s.ADs[account].Coordinate);
        uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() - s.ADs[account].PerMOPNPointMinted;

        if (AccountPerMOPNPointMintedDiff > 0 && AccountOnMapMOPNPoint > 0) {
            inbox += ((AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) * 9) / 10;
            uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(getAccountCollection(account)) -
                s.ADs[account].PerCollectionNFTMinted;

            if (AccountPerCollectionNFTMintedDiff > 0) {
                inbox += (AccountPerCollectionNFTMintedDiff * 9) / 10;
            }
        }
    }

    function calcLandsMT(uint32[] memory LandIds, address[][] memory tileAccounts) public view returns (uint256[] memory amounts) {
        amounts = new uint256[](LandIds.length);
        for (uint256 i = 0; i < LandIds.length; i++) {
            amounts[i] = calcLandMT(LandIds[i], tileAccounts[i]);
        }
    }

    function calcLandMT(uint32 LandId, address[] memory tileAccounts) public view returns (uint256 amount) {
        uint24 tileCoordinate = tileAtLandCenter(LandId);
        for (uint256 i; i < tileAccounts.length; i++) {
            if (tiledistance(tileCoordinate, s.ADs[tileAccounts[i]].Coordinate) < 6) {
                amount += calcLandAccountMT(tileAccounts[i]);
            }
        }
    }

    function calcLandAccountMT(address account) public view returns (uint256 amount) {
        if (account != address(0)) {
            uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() - s.ADs[account].PerMOPNPointMinted;

            if (AccountPerMOPNPointMintedDiff > 0) {
                address collectionAddress = getAccountCollection(account);
                uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(collectionAddress) - s.ADs[account].PerCollectionNFTMinted;
                uint256 AccountOnMapMOPNPoint = tilepoint(s.ADs[account].Coordinate);
                amount += (AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) / 20;
                if (AccountPerCollectionNFTMintedDiff > 0) {
                    amount += AccountPerCollectionNFTMintedDiff / 20;
                }
            }
        }
    }

    function getAccountData(address account) public view returns (AccountDataOutput memory accountData) {
        accountData.account = account;
        (, address collectionAddress, uint256 tokenId) = IMOPNERC6551Account(payable(account)).token();

        accountData.tokenId = tokenId;
        accountData.contractAddress = collectionAddress;
        accountData.AgentPlacer = s.ADs[account].AgentPlacer;
        accountData.AgentAssignPercentage = s.ADs[account].AgentAssignPercentage;
        accountData.owner = IMOPNERC6551Account(payable(account)).owner();
        accountData.MTBalance = IMOPNToken(s.tokenContract).balanceOf(account);
        accountData.OnMapMOPNPoint = tilepoint(s.ADs[account].Coordinate);
        accountData.CollectionMOPNPoint = s.CDs[collectionAddress].CollectionMOPNPoint;
        accountData.TotalMOPNPoint = accountData.OnMapMOPNPoint + accountData.CollectionMOPNPoint;
        accountData.tileCoordinate = s.ADs[account].Coordinate;
    }

    function getAccountsData(address[] memory accounts) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            accountDatas[i] = getAccountData(accounts[i]);
        }
    }

    function getAccountByNFT(NFTParams calldata params) public view returns (address) {
        return IERC6551Registry(s.ERC6551Registry).account(s.ERC6551AccountProxy, block.chainid, params.collectionAddress, params.tokenId, 0);
    }

    /**
     * @notice get avatar info by nft contractAddress and tokenId
     * @param params  collection contract address and tokenId
     * @return accountData avatar data format struct AvatarDataOutput
     */
    function getAccountDataByNFT(NFTParams calldata params) public view returns (AccountDataOutput memory accountData) {
        accountData = getAccountData(getAccountByNFT(params));
    }

    /**
     * @notice get avatar infos by nft contractAddresses and tokenIds
     * @param params array of collection contract address and token ids
     * @return accountDatas avatar datas format struct AvatarDataOutput
     */
    function getAccountsDataByNFTs(NFTParams[] calldata params) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            accountDatas[i] = getAccountData(getAccountByNFT(params[i]));
        }
    }

    function getBatchAccountMTBalance(address[] memory accounts) public view returns (uint256[] memory MTBalances) {
        MTBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            MTBalances[i] = IMOPNToken(s.tokenContract).balanceOf(accounts[i]);
        }
    }

    function getWalletStakingMTs(address[] memory collections, address wallet) public view returns (uint256 amount) {
        for (uint256 i = 0; i < collections.length; i++) {
            amount += IMOPNCollectionVault(s.CDs[collections[i]].vaultAddress).V2MTAmountRealtime(
                IMOPNCollectionVault(s.CDs[collections[i]].vaultAddress).balanceOf(wallet)
            );
        }
    }

    /**
     * get collection contract, on map num, avatar num etc from IGovernance.
     */
    function getCollectionData(address collectionAddress) public view returns (CollectionDataOutput memory cData) {
        cData.contractAddress = collectionAddress;
        cData.collectionVault = s.CDs[collectionAddress].vaultAddress;
        cData.OnMapNum = s.CDs[collectionAddress].OnMapNftNumber;
        cData.OnMapAgentPlaceNftNumber = s.CDs[collectionAddress].OnMapAgentPlaceNftNumber;
        cData.MTBalance = IMOPNToken(s.tokenContract).balanceOf(cData.collectionVault);
        cData.UnclaimMTBalance = calcCollectionSettledMT(collectionAddress);
        cData.OnMapMOPNPoints = s.CDs[collectionAddress].OnMapMOPNPoints;

        if (cData.collectionVault != address(0)) {
            cData.AskStruct = IMOPNCollectionVault(cData.collectionVault).getAskInfo();
            cData.BidStruct = IMOPNCollectionVault(cData.collectionVault).getBidInfo();
            cData.PMTTotalSupply = IMOPNCollectionVault(cData.collectionVault).totalSupply();
            cData.CollectionMOPNPoint = IMOPNCollectionVault(cData.collectionVault).getCollectionMOPNPoint();
            cData.CollectionMOPNPoints = cData.CollectionMOPNPoint * cData.OnMapNum;
        } else {
            cData.BidStruct.currentPrice = cData.UnclaimMTBalance / 5;
        }
    }

    function getCollectionsData(address[] memory collectionAddresses) public view returns (CollectionDataOutput[] memory cDatas) {
        cDatas = new CollectionDataOutput[](collectionAddresses.length);
        for (uint256 i = 0; i < collectionAddresses.length; i++) {
            cDatas[i] = getCollectionData(collectionAddresses[i]);
        }
    }

    function getCollectionVaultIndex(address collectionAddress) public view returns (uint256) {
        return s.CDs[collectionAddress].vaultIndex;
    }

    function getTotalCollectionVaultMinted() public view returns (uint256) {
        return ((s.MTTotalMinted + (calcPerMOPNPointMinted() - s.PerMOPNPointMinted) * s.TotalMOPNPoints) / 20);
    }
}
