// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ILandMetaDataRender.sol";
import "./libraries/NFTMetaData.sol";

contract LandMetaDataRenderSolo is ILandMetaDataRender {
    function constructTokenURI(
        uint256 LandId_
    ) public pure returns (string memory) {
        uint32 LandId = uint32(LandId_);
        NFTSVG.tileData[] memory tileDatas = new NFTSVG.tileData[](91);
        uint32 tileCoordinate = TileMath.LandCenterTile(LandId);

        tileDatas[0].tileEAW = TileMath.getTileEAW(tileCoordinate);

        uint256 index;
        for (uint256 i = 1; i <= 5; i++) {
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            tileCoordinate++;
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    index = preringblocks + j * i + k + 1;
                    tileDatas[index].tileEAW = TileMath.getTileEAW(
                        tileCoordinate
                    );

                    tileCoordinate = TileMath.neighbor(tileCoordinate, j);
                }
            }
        }

        return NFTMetaData.constructTokenURI(LandId, tileDatas, 0);
    }
}
