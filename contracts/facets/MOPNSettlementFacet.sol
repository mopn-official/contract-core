// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {FacetCommons} from "./FacetCommons.sol";
import {LibMOPN, Modifiers} from "../libraries/LibMOPN.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Constants} from "contracts/libraries/Constants.sol";
import {Errors} from "contracts/libraries/Errors.sol";
import {Events} from "contracts/libraries/Events.sol";
import "../erc6551/interfaces/IMOPNERC6551Account.sol";
import "../erc6551/interfaces/IERC6551Registry.sol";
import "../interfaces/IMOPNCollectionVault.sol";
import "../interfaces/IMOPNBomb.sol";
import "../interfaces/IMOPNToken.sol";
import "../interfaces/IMOPNLand.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/

/// @title MOPN Contract
/// @author Cyanface <cyanface@outlook.com>
contract MOPNSettlementFacet is Modifiers, FacetCommons {
    function claimCollectionMT(address collectionAddress) external onlyCollectionVault(collectionAddress) {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        if (s.CDs[collectionAddress].SettledMT > 0) {
            require(s.CDs[collectionAddress].vaultAddress != address(0), "collection vault not created");
            IMOPNToken(s.tokenContract).mint(s.CDs[collectionAddress].vaultAddress, s.CDs[collectionAddress].SettledMT);

            s.CDs[collectionAddress].SettledMT = 0;
        }
    }

    function settleCollectionMOPNPoint(address collectionAddress, uint24 point) external onlyCollectionVault(collectionAddress) {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        if (point > s.CDs[collectionAddress].CollectionMOPNPoint) {
            s.TotalMOPNPoints += (point - s.CDs[collectionAddress].CollectionMOPNPoint) * s.CDs[collectionAddress].OnMapNftNumber;
        } else if (point < s.CDs[collectionAddress].CollectionMOPNPoint) {
            s.TotalMOPNPoints -= (s.CDs[collectionAddress].CollectionMOPNPoint - point) * s.CDs[collectionAddress].OnMapNftNumber;
        }

        s.CDs[collectionAddress].CollectionMOPNPoint = point;
        emit Events.CollectionPointChange(collectionAddress, point);
    }

    function batchClaimAccountMT(address[][] memory accounts) public {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        settlePerMOPNPointMinted();
        uint256 amount;
        for (uint256 i = 0; i < accounts.length; i++) {
            for (uint256 k = 0; k < accounts[i].length; k++) {
                if (k == 0) {
                    settleCollectionMT(LibMOPN.getAccountCollection(accounts[i][k]));
                }

                if (IMOPNERC6551Account(payable(accounts[i][k])).isOwner(msg.sender)) {
                    if (s.ADs[accounts[i][k]].Coordinate > 0) {
                        settleAccountMT(accounts[i][k], LibMOPN.getAccountCollection(accounts[i][k]));
                    }
                    if (s.ADs[accounts[i][k]].SettledMT > 0) {
                        amount += s.ADs[accounts[i][k]].SettledMT;
                        s.ADs[accounts[i][k]].SettledMT = 0;
                    }
                }
            }
        }
        if (amount > 0) IMOPNToken(s.tokenContract).mint(msg.sender, amount);
    }

    function claimAccountMT(address account) external {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        if (IMOPNERC6551Account(payable(account)).isOwner(msg.sender)) {
            if (s.ADs[account].Coordinate > 0) {
                settlePerMOPNPointMinted();
                address collectionAddress = LibMOPN.getAccountCollection(account);
                settleCollectionMT(collectionAddress);
                settleAccountMT(account, collectionAddress);
            }

            if (s.ADs[account].SettledMT > 0) {
                IMOPNToken(s.tokenContract).mint(msg.sender, s.ADs[account].SettledMT);
                s.ADs[account].SettledMT = 0;
            }
        }
    }

    function batchClaimLandMT(uint16[] memory LandIds) public {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        uint256 amount;
        for (uint256 i = 0; i < LandIds.length; i++) {
            if (IMOPNLand(s.landContract).ownerOf(LandIds[i]) == msg.sender) {
                if (s.Lands[LandIds[i]] > 0) {
                    amount += s.Lands[LandIds[i]];
                    s.Lands[LandIds[i]] = 0;
                }
            }
        }
        if (amount > 0) IMOPNToken(s.tokenContract).mint(msg.sender, amount);
    }

    function claimLandMT(uint16 LandId) external {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        if (IMOPNLand(s.landContract).ownerOf(LandId) == msg.sender) {
            if (s.Lands[LandId] > 0) {
                IMOPNToken(s.tokenContract).mint(msg.sender, s.Lands[LandId]);
                s.Lands[LandId] = 0;
            }
        }
    }
}