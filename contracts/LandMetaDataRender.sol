// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ILandMetaDataRender.sol";
import "./interfaces/IMap.sol";
import "./interfaces/IMiningData.sol";
import "./interfaces/IGovernance.sol";
import "./libraries/NFTMetaData.sol";

contract LandMetaDataRender is ILandMetaDataRender {
    IGovernance public governance;

    /**
     * @dev set the governance contract address
     * @dev this function also get the Map contract from the governances
     * @param governance_ Governance Contract Address
     */
    constructor(address governance_) {
        governance = IGovernance(governance_);
    }

    function constructTokenURI(
        uint256 LandId_
    ) public view returns (string memory) {
        IMap map = IMap(governance.mapContract());

        uint32 LandId = uint32(LandId_);
        NFTSVG.tileData[] memory tileDatas = new NFTSVG.tileData[](91);
        uint32 tileCoordinate = TileMath.LandCenterTile(LandId);
        uint32[3] memory centerTileArr = TileMath.coordinateIntToArr(
            tileCoordinate
        );

        tileDatas[0].tileNFTPoint = TileMath.getTileNFTPoint(tileCoordinate);
        uint256 COID = map.getTileCOID(tileCoordinate);
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
                    tileDatas[index].tileNFTPoint = TileMath.getTileNFTPoint(
                        tileCoordinate
                    );
                    COID = map.getTileCOID(tileCoordinate);
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

        IMiningData miningData = IMiningData(governance.miningDataContract());
        return
            NFTMetaData.constructTokenURI(
                LandId,
                tileDatas,
                ((miningData.getLandHolderTotalMinted(LandId) +
                    miningData.getLandHolderInboxMT(LandId)) / 10 ** 8)
            );
    }
}
