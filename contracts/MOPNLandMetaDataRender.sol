// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPNLandMetaDataRender.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNData.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./libraries/NFTMetaData.sol";

contract MOPNLandMetaDataRender is IMOPNLandMetaDataRender {
    IMOPNGovernance public governance;

    /**
     * @dev set the governance contract address
     * @dev this function also get the Map contract from the governances
     * @param governance_ Governance Contract Address
     */
    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function constructTokenURI(
        uint256 LandId_
    ) public view returns (string memory) {
        IMOPN mopn = IMOPN(governance.mopnContract());

        uint32 LandId = uint32(LandId_);
        NFTSVG.tileData[] memory tileDatas = new NFTSVG.tileData[](91);
        uint32 tileCoordinate = TileMath.LandCenterTile(LandId);
        uint32[3] memory centerTileArr = TileMath.coordinateIntToArr(
            tileCoordinate
        );

        address[] memory collections = new address[](30);
        address collection;
        uint256 COID;
        tileDatas[0].tileMOPNPoint = TileMath.getTileMOPNPoint(tileCoordinate);

        address tileAccount = mopn.getTileAccount(tileCoordinate);
        if (tileAccount != address(0)) {
            (collection, ) = mopn.getAccountNFT(tileAccount);
            COID++;
            collections[COID] = collection;
        }

        if (COID > 0) {
            tileDatas[0].color = COID;
            tileDatas[1].color = COID;
            tileDatas[2].color = COID;
            tileDatas[3].color = COID;
            tileDatas[4].color = COID;
            tileDatas[5].color = COID;
            tileDatas[6].color = COID;
        }

        uint256 index;
        uint256 roundIndex;
        for (uint256 i = 1; i <= 5; i++) {
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            tileCoordinate++;
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    index = preringblocks + j * i + k + 1;
                    tileDatas[index].tileMOPNPoint = TileMath.getTileMOPNPoint(
                        tileCoordinate
                    );

                    tileAccount = mopn.getTileAccount(tileCoordinate);
                    if (tileAccount != address(0)) {
                        (collection, ) = mopn.getAccountNFT(tileAccount);
                        COID = exists(collections, collection);
                        if (COID == 0) {
                            COID++;
                            collections[COID] = collection;
                        }
                    }

                    if (COID > 0) {
                        uint32[3] memory tileCoordinateArr = TileMath
                            .coordinateIntToArr(tileCoordinate);

                        if (i == 1) {
                            tileDatas[0].color = COID;
                        } else {
                            roundIndex = index - (i - 1) * 6 - j;
                            if (
                                tileCoordinateArr[0] == centerTileArr[0] ||
                                tileCoordinateArr[1] == centerTileArr[1] ||
                                tileCoordinateArr[2] == centerTileArr[2]
                            ) {
                                tileDatas[roundIndex].color = COID;
                            } else {
                                roundIndex--;
                                if (roundIndex == preringblocks) {
                                    tileDatas[roundIndex].color = COID;
                                    tileDatas[roundIndex - (i - 1) * 6 + 1]
                                        .color = COID;
                                } else {
                                    tileDatas[roundIndex].color = COID;
                                    tileDatas[roundIndex + 1].color = COID;
                                }
                            }
                        }
                        if (index == preringblocks + 1) {
                            tileDatas[preringblocks + i * 6].color = COID;
                            tileDatas[index].color = COID;
                            tileDatas[index + 1].color = COID;
                        } else if (index == preringblocks + i * 6) {
                            tileDatas[index - 1].color = COID;
                            tileDatas[index].color = COID;
                            tileDatas[preringblocks + 1].color = COID;
                        } else {
                            tileDatas[index - 1].color = COID;
                            tileDatas[index].color = COID;
                            tileDatas[index + 1].color = COID;
                        }
                        roundIndex = index + i * 6 + j;
                        if (roundIndex < 91) {
                            if (
                                tileCoordinateArr[0] == centerTileArr[0] ||
                                tileCoordinateArr[1] == centerTileArr[1] ||
                                tileCoordinateArr[2] == centerTileArr[2]
                            ) {
                                if (roundIndex == preringblocks + i * 6 + 1) {
                                    tileDatas[
                                        preringblocks + i * 6 + (i + 1) * 6
                                    ].color = COID;
                                    tileDatas[roundIndex].color = COID;
                                    tileDatas[roundIndex + 1].color = COID;
                                } else {
                                    tileDatas[roundIndex - 1].color = COID;
                                    tileDatas[roundIndex].color = COID;
                                    tileDatas[roundIndex + 1].color = COID;
                                }
                            } else {
                                tileDatas[roundIndex].color = COID;
                                tileDatas[roundIndex + 1].color = COID;
                            }
                        }
                    }

                    tileCoordinate = TileMath.neighbor(tileCoordinate, j);
                }
            }
        }

        return
            NFTMetaData.constructTokenURI(
                LandId,
                tileDatas,
                getMintedMT(LandId)
            );
    }

    function getMintedMT(uint32 LandId) private view returns (uint256) {
        IMOPNData mopnData = IMOPNData(governance.mopnDataContract());
        return ((mopnData.getLandHolderTotalMinted(LandId) +
            mopnData.getLandHolderInboxMT(LandId)) / 10 ** 8);
    }

    function exists(
        address[] memory arr,
        address item
    ) public pure returns (uint256) {
        for (uint i = 1; i < arr.length; i++) {
            if (arr[i] == item) {
                return i;
            }
        }

        return 0;
    }
}
