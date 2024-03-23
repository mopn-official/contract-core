// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "hardhat/console.sol";

import {Constants} from "contracts/libraries/Constants.sol";
import {Errors} from "contracts/libraries/Errors.sol";
import {Events} from "contracts/libraries/Events.sol";
import {LibMOPN} from "contracts/libraries/LibMOPN.sol";
import "../erc6551/interfaces/IMOPNERC6551Account.sol";
import "../erc6551/interfaces/IERC6551Registry.sol";
import "../interfaces/IMOPNCollectionVault.sol";
import "../interfaces/IMOPNBomb.sol";
import "../interfaces/IMOPNToken.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

abstract contract FacetCommons {
    /**
     * get current mt produce per block
     * @param reduceTimes reduce times
     */
    function currentMTPPB(uint256 reduceTimes) internal view returns (uint256 MTPPB) {
        int128 reducePercentage = ABDKMath64x64.divu(997, 1000);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, LibMOPN.mopnStorage().MTOutputPerTimestamp);
    }

    function MTReduceTimes() internal view returns (uint256) {
        return (block.timestamp - LibMOPN.mopnStorage().MTStepStartTimestamp) / Constants.MTReduceInterval;
    }

    function settlePerMOPNPointMinted() internal {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        if (block.timestamp > s.LastTickTimestamp) {
            uint256 reduceTimes = MTReduceTimes();
            unchecked {
                if (s.TotalMOPNPoints > 0) {
                    uint256 perMOPNPointMintDiff;
                    if (reduceTimes == 0) {
                        perMOPNPointMintDiff += ((block.timestamp - s.LastTickTimestamp) * s.MTOutputPerTimestamp) / s.TotalMOPNPoints;
                    } else {
                        uint256 nextReduceTimestamp = s.MTStepStartTimestamp + Constants.MTReduceInterval;
                        uint256 lastTickTimestamp = s.LastTickTimestamp;
                        for (uint256 i = 0; i <= reduceTimes; i++) {
                            perMOPNPointMintDiff += ((nextReduceTimestamp - lastTickTimestamp) * currentMTPPB(i)) / s.TotalMOPNPoints;
                            lastTickTimestamp = nextReduceTimestamp;
                            nextReduceTimestamp += Constants.MTReduceInterval;
                            if (nextReduceTimestamp > block.timestamp) {
                                nextReduceTimestamp = block.timestamp;
                            }
                        }

                        s.MTOutputPerTimestamp = uint32(currentMTPPB(reduceTimes));
                        s.MTStepStartTimestamp += uint32(reduceTimes * Constants.MTReduceInterval);
                    }
                    s.PerMOPNPointMinted += uint48(perMOPNPointMintDiff);
                    s.MTTotalMinted += uint64(perMOPNPointMintDiff * s.TotalMOPNPoints);
                }

                s.LastTickTimestamp = uint32(block.timestamp);
            }
        }
    }

    function settleCollectionMT(address collectionAddress) internal {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        unchecked {
            uint48 collectionPerMOPNPointMintedDiff = s.PerMOPNPointMinted - s.CDs[collectionAddress].PerMOPNPointMinted;
            if (collectionPerMOPNPointMintedDiff > 0) {
                if (s.CDs[collectionAddress].OnMapNftNumber > 0) {
                    uint48 collectionMOPNPoints = s.CDs[collectionAddress].OnMapNftNumber * s.CDs[collectionAddress].CollectionMOPNPoint;

                    uint48 amount = (collectionPerMOPNPointMintedDiff * (s.CDs[collectionAddress].OnMapMOPNPoints + collectionMOPNPoints)) / 20;

                    if (collectionMOPNPoints > 0) {
                        s.CDs[collectionAddress].PerCollectionNFTMinted +=
                            (collectionPerMOPNPointMintedDiff * collectionMOPNPoints) /
                            s.CDs[collectionAddress].OnMapNftNumber;
                    }

                    s.CDs[collectionAddress].SettledMT += amount;
                    emit Events.CollectionMTMinted(collectionAddress, amount);
                }
                s.CDs[collectionAddress].PerMOPNPointMinted = s.PerMOPNPointMinted;
            }
        }
    }

    /**
     * @notice mint avatar mopn token
     * @param account account wallet address
     */
    function settleAccountMT(address account, address collectionAddress) internal {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        unchecked {
            uint48 accountPerMOPNPointMintedDiff = s.CDs[collectionAddress].PerMOPNPointMinted - s.ADs[account].PerMOPNPointMinted;
            if (accountPerMOPNPointMintedDiff > 0) {
                if (s.ADs[account].Coordinate > 0) {
                    uint48 accountOnMapMOPNPoint = LibMOPN.tilepoint(s.ADs[account].Coordinate);

                    uint48 amount = accountPerMOPNPointMintedDiff *
                        accountOnMapMOPNPoint +
                        (s.CDs[collectionAddress].PerCollectionNFTMinted - s.ADs[account].PerCollectionNFTMinted);

                    s.Lands[s.ADs[account].LandId] += amount / 20;
                    emit Events.LandHolderMTMinted(s.ADs[account].LandId, amount / 20);

                    amount = (amount * 9) / 10;
                    if (s.ADs[account].AgentPlacer != address(0)) {
                        IMOPNToken(s.tokenContract).mint(s.ADs[account].AgentPlacer, (amount * s.ADs[account].AgentAssignPercentage) / 10000);

                        amount -= (amount * s.ADs[account].AgentAssignPercentage) / 10000;
                        s.ADs[account].AgentPlacer = address(0);
                        s.CDs[collectionAddress].OnMapAgentPlaceNftNumber--;
                    }

                    emit Events.AccountMTMinted(account, amount, s.ADs[account].AgentAssignPercentage);
                    s.ADs[account].AgentAssignPercentage = 0;
                    s.ADs[account].SettledMT += amount;
                }
                s.ADs[account].PerMOPNPointMinted = s.CDs[collectionAddress].PerMOPNPointMinted;
                s.ADs[account].PerCollectionNFTMinted = s.CDs[collectionAddress].PerCollectionNFTMinted;
            }
        }
    }
}
