// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {FacetCommons} from "./FacetCommons.sol";
import {LibMOPN, Modifiers, BitMaps} from "../libraries/LibMOPN.sol";
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
contract MOPNFacet is Modifiers, FacetCommons {
    using BitMaps for BitMaps.BitMap;

    function checkAccountQualification(address account) public view returns (address collectionAddress) {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        try IMOPNERC6551Account(payable(account)).token() returns (uint256 chainId, address collectionAddress_, uint256 tokenId) {
            if (s.ADs[account].PerMOPNPointMinted == 0) {
                require(chainId == block.chainid, "not support cross chain account");
                require(
                    account == IERC6551Registry(s.ERC6551Registry).account(s.ERC6551AccountProxy, block.chainid, collectionAddress, tokenId, 0),
                    "not a mopn Account Implementation"
                );
            }
            collectionAddress = collectionAddress_;
        } catch (bytes memory) {
            require(false, "account error");
        }
    }

    /**
     * @notice an on map NFT move to a new tile
     * @param tileCoordinate move To coordinate
     */
    function moveTo(address account, uint24 tileCoordinate, uint16 LandId, address[] memory tileAccounts) external {
        _moveTo(account, tileCoordinate, LandId, tileAccounts, checkAccountQualification(account));
    }

    function moveToNFT(
        address collectionAddress,
        uint256 tokenId,
        uint24 tileCoordinate,
        uint16 LandId,
        address[] memory tileAccounts,
        bytes calldata initData
    ) external {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        address account = IERC6551Registry(s.ERC6551Registry).createAccount(
            s.ERC6551AccountProxy,
            block.chainid,
            collectionAddress,
            tokenId,
            0,
            initData
        );
        _moveTo(account, tileCoordinate, LandId, tileAccounts, collectionAddress);
    }

    function _moveTo(address account, uint24 tileCoordinate, uint16 LandId, address[] memory tileAccounts, address collectionAddress) internal {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        bool isOwner;
        try IMOPNERC6551Account(payable(account)).isOwner(msg.sender) returns (bool isOwner_) {
            isOwner = isOwner_;
            if (s.ADs[account].Coordinate > 0) {
                require(isOwner, "not account owner");
            }
        } catch (bytes memory) {
            require(false, "account owner error");
        }

        require(block.timestamp >= s.MTStepStartTimestamp, "mopn is not open yet");

        require(LibMOPN.tiledistance(tileCoordinate, LibMOPN.tileAtLandCenter(LandId)) < 6, "LandId error");

        require(LandId < 10981, "Land Overflow");

        settlePerMOPNPointMinted();
        settleCollectionMT(collectionAddress);
        settleAccountMT(account, collectionAddress);
        uint256 dstBitMap;

        unchecked {
            if (s.tilesbitmap.get(tileCoordinate)) {
                require(tileCoordinate == s.ADs[tileAccounts[0]].Coordinate, "tile accounts error");
                address tileAccountCollection = LibMOPN.getAccountCollection(tileAccounts[0]);
                require(collectionAddress != tileAccountCollection, "dst has ally");

                dstBitMap += 1 << 100;
                bombATile(account, tileCoordinate, tileAccounts[0], tileAccountCollection);
            }

            tileCoordinate++;
            for (uint256 i = 0; i < 18; i++) {
                if (!get256bitmap(dstBitMap, i) && s.tilesbitmap.get(tileCoordinate)) {
                    require(tileCoordinate == s.ADs[tileAccounts[i + 1]].Coordinate, "tile accounts error");
                    if (tileAccounts[i + 1] != account) {
                        address tileAccountCollection = LibMOPN.getAccountCollection(tileAccounts[i + 1]);
                        if (tileAccountCollection == collectionAddress) {
                            dstBitMap = set256bitmap(dstBitMap, 50);
                            uint256 k = i;
                            if (i < 5) {
                                k++;
                                while (k < 6) {
                                    dstBitMap = set256bitmap(dstBitMap, k);
                                    k++;
                                }
                                k = 3 + i * 2;

                                dstBitMap |= (127 << k);
                            } else {
                                dstBitMap = set256bitmap(dstBitMap, k + 1);
                                dstBitMap = set256bitmap(dstBitMap, k + 2);
                            }
                        } else {
                            dstBitMap += 1 << 100;

                            bombATile(account, tileCoordinate, tileAccounts[i + 1], tileAccountCollection);
                        }
                    }
                }
                if (i == 5) {
                    tileCoordinate += 10001;
                } else if (i < 5) {
                    tileCoordinate = LibMOPN.tileneighbor(tileCoordinate, i);
                } else {
                    tileCoordinate = LibMOPN.tileneighbor(tileCoordinate, (i - 6) / 2);
                }
            }
            if ((dstBitMap >> 100) > 0) {
                IMOPNBomb(s.bombContract).burn(msg.sender, 1, dstBitMap >> 100);
            }
            tileCoordinate -= 2;
        }

        require(
            get256bitmap(dstBitMap, 50) ||
                (s.CDs[collectionAddress].OnMapNftNumber == 0 || (s.ADs[account].Coordinate > 0 && s.CDs[collectionAddress].OnMapNftNumber == 1)),
            "linked account missing"
        );

        uint48 tileMOPNPoint = LibMOPN.tilepoint(tileCoordinate);
        if (s.ADs[account].Coordinate > 0) {
            emit Events.AccountMove(account, LandId, s.ADs[account].Coordinate, tileCoordinate);
            s.tilesbitmap.unset(s.ADs[account].Coordinate);
            uint48 orgMOPNPoint = LibMOPN.tilepoint(s.ADs[account].Coordinate);

            unchecked {
                if (tileMOPNPoint > orgMOPNPoint) {
                    tileMOPNPoint -= orgMOPNPoint;
                    s.TotalMOPNPoints += tileMOPNPoint;
                    s.CDs[collectionAddress].OnMapMOPNPoints += tileMOPNPoint;
                } else if (tileMOPNPoint < orgMOPNPoint) {
                    tileMOPNPoint = orgMOPNPoint - tileMOPNPoint;
                    s.TotalMOPNPoints -= tileMOPNPoint;
                    s.CDs[collectionAddress].OnMapMOPNPoints -= tileMOPNPoint;
                }
            }
        } else {
            require(s.CDs[collectionAddress].OnMapNftNumber < Constants.MaxCollectionOnMapNum, "collection on map nft number overflow");

            if (!isOwner) {
                s.ADs[account].AgentPlacer = msg.sender;
                s.ADs[account].AgentAssignPercentage = getCollectionAgentAssignPercentage(collectionAddress);
                s.CDs[collectionAddress].OnMapAgentPlaceNftNumber++;

                emit Events.AccountJumpIn(account, LandId, tileCoordinate, msg.sender, s.ADs[account].AgentAssignPercentage);
            } else {
                emit Events.AccountJumpIn(account, LandId, tileCoordinate, address(0), 0);
            }
            unchecked {
                s.TotalMOPNPoints += tileMOPNPoint + s.CDs[collectionAddress].CollectionMOPNPoint;

                s.CDs[collectionAddress].OnMapMOPNPoints += tileMOPNPoint;
                s.CDs[collectionAddress].OnMapNftNumber++;
            }
        }

        s.ADs[account].LandId = LandId;
        s.ADs[account].Coordinate = tileCoordinate;

        s.tilesbitmap.set(tileCoordinate);

        if (dstBitMap >> 100 > 0) {
            gasDraw(dstBitMap >> 100);
        }
    }

    function bombATile(address account, uint24 tileCoordinate, address tileAccount, address tileAccountCollection) internal {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        s.tilesbitmap.unset(tileCoordinate);

        settleCollectionMT(tileAccountCollection);
        settleAccountMT(tileAccount, tileAccountCollection);

        uint48 accountOnMapMOPNPoint = LibMOPN.tilepoint(tileCoordinate);

        unchecked {
            s.TotalMOPNPoints -= accountOnMapMOPNPoint + s.CDs[tileAccountCollection].CollectionMOPNPoint;

            s.CDs[tileAccountCollection].OnMapMOPNPoints -= accountOnMapMOPNPoint;
            s.CDs[tileAccountCollection].OnMapNftNumber--;

            s.ADs[tileAccount].LandId = 0;
            s.ADs[tileAccount].Coordinate = 0;
        }
        emit Events.BombUse(account, tileAccount, tileCoordinate);
    }

    function gasDraw(uint256 times) internal nonReentrant {
        uint256 gasdraw = generateRandomNumber(10000);
        for (uint256 i = 0; i < times; i++) {
            gasdraw += i;
            if (gasdraw == 10000) {
                uint256 half = address(this).balance / 2;
                if (half > 0) {
                    (bool sent, ) = msg.sender.call{value: half}("");
                    require(sent, "Failed to send Ether");
                }
                break;
            }
        }
    }

    function generateRandomNumber(uint _modulus) public view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao)));
        return (randomHash % _modulus) + 1;
    }

    function getCollectionAgentAssignPercentage(address collectionAddress) public view returns (uint16) {
        int128 reducePercentage = ABDKMath64x64.divu(9994, 10000);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, LibMOPN.mopnStorage().CDs[collectionAddress].OnMapAgentPlaceNftNumber);
        return uint16(ABDKMath64x64.mulu(reducePower, 6000));
    }

    function get256bitmap(uint256 bitmap, uint256 index) public pure returns (bool) {
        unchecked {
            return bitmap & (1 << index) != 0;
        }
    }

    function set256bitmap(uint256 bitmap, uint256 index) public pure returns (uint256) {
        unchecked {
            bitmap |= (1 << index);
            return bitmap;
        }
    }
}
