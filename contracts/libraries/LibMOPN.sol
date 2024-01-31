// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "hardhat/console.sol";

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
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

struct AccountDataStruct {
    uint16 LandId;
    uint24 Coordinate;
    uint48 PerMOPNPointMinted;
    uint48 SettledMT;
    uint48 PerCollectionNFTMinted;
    uint16 AgentAssignPercentage;
    address AgentPlacer;
}

struct CollectionDataStruct {
    uint24 CollectionMOPNPoint;
    uint48 OnMapMOPNPoints;
    uint16 OnMapNftNumber;
    uint16 OnMapAgentPlaceNftNumber;
    uint48 PerCollectionNFTMinted;
    uint48 PerMOPNPointMinted;
    uint48 SettledMT;
    address vaultAddress;
    uint48 vaultIndex;
}

struct BombSoldStruct {
    uint16[24] hourSolds;
    uint32 lastSellTimestamp;
}

struct NFTParams {
    address collectionAddress;
    uint256 tokenId;
}

struct AccountDataOutput {
    address account;
    address contractAddress;
    uint256 tokenId;
    uint256 CollectionMOPNPoint;
    uint256 MTBalance;
    uint256 OnMapMOPNPoint;
    uint256 TotalMOPNPoint;
    uint32 tileCoordinate;
    address owner;
    address AgentPlacer;
    uint256 AgentAssignPercentage;
}

struct CollectionDataOutput {
    address contractAddress;
    address collectionVault;
    uint256 OnMapNum;
    uint256 MTBalance;
    uint256 UnclaimMTBalance;
    uint256 CollectionMOPNPoints;
    uint256 OnMapMOPNPoints;
    uint256 CollectionMOPNPoint;
    uint256 PMTTotalSupply;
    uint256 OnMapAgentPlaceNftNumber;
    IMOPNCollectionVault.AskStruct AskStruct;
    IMOPNCollectionVault.BidStruct BidStruct;
}

struct MOPNStorage {
    uint32 LastTickTimestamp;
    uint48 TotalMOPNPoints;
    uint48 PerMOPNPointMinted;
    uint64 MTTotalMinted;
    uint32 MTOutputPerTimestamp;
    uint32 MTStepStartTimestamp;
    uint16 nextLandId;
    uint48 vaultIndex;
    uint8 reentrantStatus;
    address bombContract;
    address tokenContract;
    address landContract;
    address vaultContract;
    address ERC6551Registry;
    address ERC6551AccountProxy;
    address ERC6551AccountHelper;
    BombSoldStruct bombsold;
    BitMaps.BitMap tilesbitmap;
    mapping(address => AccountDataStruct) ADs;
    mapping(address => CollectionDataStruct) CDs;
    mapping(uint32 => uint256) Lands;
}

function mopnStorage() pure returns (MOPNStorage storage ms) {
    assembly {
        ms.slot := 0
    }
}

contract MOPNBase {
    MOPNStorage internal s;

    modifier onlyDiamond() {
        if (msg.sender != address(this)) revert Errors.NotDiamond();
        _;
    }

    modifier onlyCollectionVault(address collectionAddress) {
        require(msg.sender == s.CDs[collectionAddress].vaultAddress, "only collection vault allowed");
        _;
    }

    modifier onlyToken() {
        require(msg.sender == s.tokenContract, "only token allowed");
        _;
    }

    modifier nonReentrant() {
        if (s.reentrantStatus == Constants.ENTERED) revert Errors.ReentrantCall();
        s.reentrantStatus = Constants.ENTERED;
        _;
        s.reentrantStatus = Constants.NOT_ENTERED;
    }

    modifier nonReentrantView() {
        if (s.reentrantStatus == Constants.ENTERED) revert Errors.ReentrantCallView();
        _;
    }

    uint24[] internal neighbors = [9999, 1, 10000, 9999, 1, 10000];

    function tileneighbor(uint24 tileCoordinate, uint256 direction) internal pure returns (uint24) {
        unchecked {
            if (direction == 1) {
                return tileCoordinate - 1;
            } else if (direction == 2) {
                return tileCoordinate - 10000;
            } else if (direction == 3) {
                return tileCoordinate - 9999;
            } else if (direction == 4) {
                return tileCoordinate + 1;
            } else if (direction == 5) {
                return tileCoordinate + 100000;
            } else {
                return tileCoordinate + 9999;
            }
        }
    }

    function tilepoint(uint24 tileCoordinate) internal pure returns (uint48) {
        if (tileCoordinate == 0) {
            return 0;
        }
        unchecked {
            if ((tileCoordinate / 10000) % 10 == 0) {
                if (tileCoordinate % 10 == 0) {
                    return 1500;
                }
                return 500;
            } else if (tileCoordinate % 10 == 0) {
                return 500;
            }
            return 100;
        }
    }

    function tiledistance(uint24 a, uint24 b) internal pure returns (uint24 d) {
        unchecked {
            uint24 at = a / 10000;
            uint24 bt = b / 10000;
            d += at > bt ? at - bt : bt - at;
            at = a % 10000;
            bt = b % 10000;
            d += at > bt ? at - bt : bt - at;
            at = 3000 - a / 10000 - at;
            bt = 3000 - b / 10000 - bt;
            d += at > bt ? at - bt : bt - at;
            d /= 2;
        }
    }

    function tileAtLandCenter(uint256 LandId) internal pure returns (uint24) {
        if (LandId == 0) {
            return 10001000;
        }
        unchecked {
            uint256 n = (Math.sqrt(9 + 12 * LandId) - 3) / 6;
            if ((3 * n * n + 3 * n) != LandId) {
                n++;
            }

            uint256 startTile = 10001000 - n * 49989;
            uint256 z = 3000 - startTile / 10000 - (startTile % 10000);

            n--;
            uint256 LandIdRingPos_ = LandId - (3 * n * n + 3 * n);
            n++;

            uint256 side = Math.ceilDiv(LandIdRingPos_, n);

            uint256 sidepos = 0;
            if (n > 1) {
                sidepos = (LandIdRingPos_ - 1) % n;
            }
            if (side == 1) {
                startTile = startTile + sidepos * 110000 - sidepos * 6;
            } else if (side == 2) {
                startTile = (2000 - z) * 10000 + (2000 - startTile / 10000);
                startTile = startTile + sidepos * 49989;
            } else if (side == 3) {
                startTile = (startTile % 10000) * 10000 + z;
                startTile = startTile - sidepos * 60005;
            } else if (side == 4) {
                startTile = 20002000 - startTile;
                startTile = startTile - sidepos * 109994;
            } else if (side == 5) {
                startTile = z * 10000 + startTile / 10000;
                startTile = startTile - sidepos * 49989;
            } else if (side == 6) {
                startTile = (2000 - (startTile % 10000)) * 10000 + (2000 - z);
                startTile = startTile + sidepos * 60005;
            }

            return uint24(startTile);
        }
    }

    /**
     * get current mt produce per block
     * @param reduceTimes reduce times
     */
    function currentMTPPB(uint256 reduceTimes) internal view returns (uint256 MTPPB) {
        int128 reducePercentage = ABDKMath64x64.divu(997, 1000);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, s.MTOutputPerTimestamp);
    }

    function MTReduceTimes() internal view returns (uint256) {
        return (block.timestamp - s.MTStepStartTimestamp) / Constants.MTReduceInterval;
    }

    function settlePerMOPNPointMinted() internal {
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
        unchecked {
            uint48 accountPerMOPNPointMintedDiff = s.CDs[collectionAddress].PerMOPNPointMinted - s.ADs[account].PerMOPNPointMinted;
            if (accountPerMOPNPointMintedDiff > 0) {
                if (s.ADs[account].Coordinate > 0) {
                    uint48 accountOnMapMOPNPoint = tilepoint(s.ADs[account].Coordinate);

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

    function getAccountCollection(address account) internal view returns (address collectionAddress) {
        (, collectionAddress, ) = IMOPNERC6551Account(payable(account)).token();
    }
}
