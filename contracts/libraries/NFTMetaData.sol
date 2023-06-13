// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./TileMath.sol";
import "./NFTSVG.sol";
import "base64-sol/base64.sol";

library NFTMetaData {
    using Strings for uint32;

    function constructTokenURI(
        uint32 LandId,
        NFTSVG.tileData[] memory tileDatas,
        uint256 MTMinted
    ) public pure returns (string memory) {
        uint32 blockCoordinate = TileMath.LandCenterTile(LandId);
        uint32 ringNum = TileMath.LandRingNum(LandId);
        string memory coordinateStr = string(
            abi.encodePacked(
                _int2str(blockCoordinate / 10000),
                ", ",
                _int2str(blockCoordinate % 10000)
            )
        );

        uint32 totalNFTPoint;
        for (uint256 i = 0; i < tileDatas.length; i++) {
            totalNFTPoint += uint32(tileDatas[i].tileNFTPoint);
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"MOPN Land #',
                            LandId.toString(),
                            '", "description":"As a proud owner of one of the 10,981 Genesis Lands in MOPN, you will be entitled to a 5% tax of the $MT (MOPN Token) generated by NFTs placed on your land."'
                            ', "attributes": ',
                            constructAttributes(
                                LandId,
                                blockCoordinate,
                                ringNum,
                                totalNFTPoint,
                                MTMinted
                            ),
                            ', "image": "',
                            constructTokenImage(
                                LandId,
                                coordinateStr,
                                tileDatas
                            ),
                            '"}'
                        )
                    )
                )
            );
    }

    function constructAttributes(
        uint32 LandId,
        uint32 blockCoordinate,
        uint32 ringNum,
        uint32 totalNFTPoint,
        uint256 MTMinted
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                '[{"trait_type": "Weights", "value": "',
                totalNFTPoint.toString(),
                '"}',
                getIntAttributesRangeBytes(blockCoordinate),
                ',{"trait_type": "Tax Revenue ($MT)", "display_type": "boost_number", "value": ',
                Strings.toString(MTMinted),
                '},{"trait_type": "Ring Number", "value": "',
                Strings.toString(ringNum),
                '"},{"trait_type": "Land ID", "display_type": "number", "max_value": 10980, "value":',
                LandId.toString(),
                "}]"
            );
    }

    function constructTokenImage(
        uint32 LandId,
        string memory coordinateStr,
        NFTSVG.tileData[] memory tileDatas
    ) public pure returns (string memory) {
        string memory defs = NFTSVG.generateDefs(landBgColor(LandId));
        string memory background = NFTSVG.generateBackground(
            LandId,
            coordinateStr
        );

        string memory blocks = NFTSVG.generateBlocks(tileDatas);

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(NFTSVG.getImage(defs, background, blocks))
                    )
                )
            );
    }

    function getIntAttributesRangeBytes(
        uint32 blockCoordinate
    ) public pure returns (bytes memory attributesBytes) {
        (uint32[] memory xrange, uint32[] memory yrange) = TileMath
            .LandTileRange(blockCoordinate);

        attributesBytes = abi.encodePacked(
            getIntAttributesArray("x", xrange),
            getIntAttributesArray("y", yrange)
        );
    }

    function getIntAttributesArray(
        string memory trait_type,
        uint32[] memory ary
    ) public pure returns (bytes memory attributesBytes) {
        for (uint256 i = 0; i < ary.length; i++) {
            attributesBytes = abi.encodePacked(
                attributesBytes,
                ', {"display_type": "number", "max_value": 665, "trait_type": "',
                trait_type,
                '", "value": ',
                _int2str(ary[i]),
                "}"
            );
        }
    }

    function landBgColor(uint32 landId) public pure returns (bytes memory) {
        if (landId == 0) {
            return abi.encodePacked("hsl(0, 100%, 100%)");
        }
        uint256 round = (landId / 360) + 1;
        uint256 pos = landId % 360;
        uint256 h = 30 * (pos % 12) + (pos / 12);

        return
            abi.encodePacked(
                "hsl(",
                Strings.toString(h),
                ",",
                Strings.toString(66 - round),
                "%, 80%)"
            );
    }

    function _int2str(uint32 n) internal pure returns (string memory) {
        if (n >= 1000) {
            return (n - 1000).toString();
        } else {
            return string(abi.encodePacked("-", (1000 - n).toString()));
        }
    }
}
