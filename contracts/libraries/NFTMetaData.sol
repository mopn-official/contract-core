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
        uint256 EnergyMinted
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

        uint32 totalEAW;
        for (uint256 i = 0; i < tileDatas.length; i++) {
            totalEAW += uint32(tileDatas[i].tileEAW);
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"MOPN Land #',
                            LandId.toString(),
                            '", "description":"The Land is a proof of support for members of the MOPN community. By holding this Land, you can recycle $ENERGY from 91 tiles centered at the tile (',
                            coordinateStr,
                            ') with a radius of 6 tiles. Other benefits of holding the Land include participating in community governance and receiving priority access to the upcoming games."'
                            ', "attributes": ',
                            constructAttributes(
                                LandId,
                                blockCoordinate,
                                ringNum,
                                totalEAW,
                                EnergyMinted
                            ),
                            ', "image": "',
                            constructTokenImage(
                                LandId,
                                ringNum,
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
        uint32 totalEAW,
        uint256 EnergyMinted
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                '[{"trait_type": "Total Energy Allocation Weight", "value": "',
                totalEAW.toString(),
                '"}',
                getIntAttributesRangeBytes(blockCoordinate),
                ',{"trait_type": "Energy Minted", "display_type": "boost_number", "value": ',
                Strings.toString(EnergyMinted),
                '},{"trait_type": "Ring Number", "value": "',
                Strings.toString(ringNum),
                '"},{"trait_type": "Land ID", "display_type": "number", "max_value": 10981, "value":',
                LandId.toString(),
                "}]"
            );
    }

    function constructTokenImage(
        uint32 LandId,
        uint32 ringNum,
        string memory coordinateStr,
        NFTSVG.tileData[] memory tileDatas
    ) public pure returns (string memory) {
        string memory defs = NFTSVG.generateDefs(ringBgColor(ringNum));
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
                ', {"display_type": "number", "max_value": 660, "trait_type": "',
                trait_type,
                '", "value": ',
                _int2str(ary[i]),
                "}"
            );
        }
    }

    function ringBgColor(uint256 ringNum) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                "hsl(",
                Strings.toString(60 + ringNum * 5),
                ", 100%, 65%)"
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
