// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./HexGridsMath.sol";
import "./NFTSVG.sol";
import "base64-sol/base64.sol";

library NFTMetaData {
    using Strings for uint32;

    enum PassType {
        REGULAR,
        SILVER,
        GOLD
    }

    function constructTokenURI(
        uint32 PassId,
        uint256 EnergyMinted
    ) public pure returns (string memory) {
        uint32 blockCoordinate = HexGridsMath.PassCenterBlock(PassId);
        uint32 ringNum = HexGridsMath.PassRingNum(PassId);
        string memory coordinateStr = string(
            abi.encodePacked(
                _int2str(blockCoordinate / 10000),
                ", ",
                _int2str(blockCoordinate % 10000)
            )
        );

        uint256[] memory blocksBEPS = HexGridsMath.getPassBlocksBEPS(PassId);
        uint32 totalBEPS;
        for (uint256 i = 0; i < blocksBEPS.length; i++) {
            totalBEPS += uint32(blocksBEPS[i]);
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"MOPN Pass #',
                            PassId.toString(),
                            '", "description":"The Pass is a proof of support for members of the MOPN community. By holding this Pass, you can recycle $ENERGY from 91 blocks centered at the block (',
                            coordinateStr,
                            ') with a radius of 6 blocks. Other benefits of holding the Pass include participating in community governance and receiving priority access to the upcoming games."'
                            ', "attributes": ',
                            constructAttributes(
                                PassId,
                                blockCoordinate,
                                ringNum,
                                totalBEPS,
                                EnergyMinted
                            ),
                            ', "image": "',
                            constructTokenImage(
                                PassId,
                                ringNum,
                                coordinateStr,
                                blocksBEPS,
                                totalBEPS
                            ),
                            '"}'
                        )
                    )
                )
            );
    }

    function constructAttributes(
        uint32 PassId,
        uint32 blockCoordinate,
        uint32 ringNum,
        uint32 totalBEPS,
        uint256 EnergyMinted
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                '[{"trait_type": "Block Type", "value": "',
                totalBEPS.toString(),
                '"}',
                getIntAttributesRangeBytes(blockCoordinate),
                ',{"trait_type": "Energy Minted", "display_type": "boost_number", "value": ',
                Strings.toString(EnergyMinted),
                '},{"trait_type": "Background Color", "value": "',
                ringBgColorName(ringNum),
                '"},{"trait_type": "Pass ID", "display_type": "number", "max_value": 10981, "value":',
                PassId.toString(),
                "}]"
            );
    }

    function constructTokenImage(
        uint32 PassId,
        uint32 ringNum,
        string memory coordinateStr,
        uint256[] memory blocksBEPS,
        uint32 totalBEPS
    ) public pure returns (string memory) {
        string memory defs = NFTSVG.generateDefs(
            ringBorderColor(ringNum),
            ringBgColor(ringNum)
        );
        string memory background = NFTSVG.generateBackground(
            PassId,
            totalBEPS,
            coordinateStr
        );

        string memory blocks = NFTSVG.generateBlocks(blocksBEPS);

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
        (uint32[] memory xrange, uint32[] memory yrange) = HexGridsMath
            .PassBlockRange(blockCoordinate);

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
        string[61] memory bgcolors = [
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#E8F3D6",
            "#FCF9BE",
            "#FFDCA9",
            "#FAAB78",
            "#FEFCF3",
            "#F5EBE0",
            "#F0DBDB",
            "#DBA39A",
            "#65647C",
            "#8B7E74",
            "#C7BCA1",
            "#F1D3B3",
            "#FBFACD",
            "#DEBACE",
            "#BA94D1",
            "#7F669D",
            "#F7A4A4",
            "#FEBE8C",
            "#FFFBC1",
            "#B6E2A1",
            "#E97777",
            "#FF9F9F",
            "#FCDDB0",
            "#7F7F7F",
            "#7F7F7F",
            "#7F7F7F",
            "#7F7F7F",
            "#7F7F7F",
            "#FFFAD7",
            "#FFE1E1",
            "#90A17D",
            "#829460",
            "#EEEEEE",
            "#B7C4CF",
            "#FFB9B9",
            "#FFDDD2",
            "#FFACC7",
            "#FF8DC7",
            "#FF8787",
            "#F8C4B4",
            "#E5EBB2",
            "#BCE29E",
            "#FDFDBD",
            "#C8FFD4",
            "#B8E8FC",
            "#B1AFFF",
            "#FFF8EA",
            "#9E7676",
            "#815B5B",
            "#594545",
            "#FAF7F0",
            "#CDFCF6",
            "#BCCEF8",
            "#554994"
        ];
        return bytes(bgcolors[ringNum]);
    }

    function ringBgColorName(
        uint256 ringNum
    ) public pure returns (bytes memory) {
        string[61] memory bgcolors = [
            "MOPN Gold",
            "MOPN Gold",
            "MOPN Gold",
            "MOPN Gold",
            "MOPN Gold",
            "MOPN Gold",
            "MOPN Gold",
            "Tokyo Underground",
            "Cashew Cheese",
            "Sarcoline",
            "Orange Marmalade",
            "Antique China",
            "Tea Biscuit",
            "Diminutive Pink",
            "Quiet Pink",
            "Old Lavender",
            "Silt",
            "Coral Reef",
            "Banana Ice Cream",
            "Morrow White",
            "Thistle",
            "Amethyst Show",
            "Purple Paradise",
            "Young Crab",
            "Reddish Banana",
            "Ice Lemon",
            "Basil Smash",
            "Geraldine",
            "Rubber Radish",
            "Apricot Mousse",
            "MOPN Silver",
            "MOPN Silver",
            "MOPN Silver",
            "MOPN Silver",
            "MOPN Silver",
            "Country Summer",
            "Red Remains",
            "Herbal Scent",
            "Green Energy",
            "Super Silver",
            "Pastel Blue",
            "Hard Candy",
            "Soft Orange Bloom",
            "Heartfelt",
            "Shimmering Love",
            "Light Coral",
            "Apricot Obsession",
            "Cucumber Cream",
            "Basil Smash",
            "Yellow Mana",
            "Mint Zest",
            "Uranian Blue",
            "Winterspring Lilac",
            "Toasted Marshmallow Fluff",
            "Regal Rose",
            "Book Binder",
            "Mahogany Spice",
            "Milk Glass",
            "Duck Egg Blue",
            "Arctic Paradise",
            "Liberty"
        ];
        return bytes(bgcolors[ringNum]);
    }

    function ringBorderColor(
        uint32 ringNum
    ) public pure returns (bytes memory) {
        string memory bordcolor = "#F2F2F2";
        if (ringNum < 7) {
            bordcolor = "#FFD965";
        } else if (ringNum > 29 && ringNum < 35) {
            bordcolor = "#595959";
        }
        return bytes(bordcolor);
    }

    function _int2str(uint32 n) internal pure returns (string memory) {
        if (n >= 1000) {
            return (n - 1000).toString();
        } else {
            return string(abi.encodePacked("-", (1000 - n).toString()));
        }
    }
}
