// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library NFTSVG {
    using Strings for uint32;

    struct coordinate {
        uint32 x;
        uint32 xdecimal;
        uint32 y;
    }

    struct tileData {
        uint256 color;
        uint256 tileMTAW;
    }

    function getBlock(
        coordinate memory co,
        uint256 blockLevel,
        uint256 fillcolor
    ) public pure returns (string memory svg) {
        string memory blockbg = ' class="b1"';
        if (fillcolor > 0) {
            blockbg = string(
                abi.encodePacked(' style="fill:', COIDToColor(fillcolor), ';"')
            );
        }
        svg = string(
            abi.encodePacked(
                '<use width="46.188" height="40" transform="translate(',
                co.x.toString(),
                ".",
                co.xdecimal.toString(),
                " ",
                co.y.toString(),
                ')"',
                blockbg,
                ' xlink:href="#Block"/>',
                blockLevel > 1 ? getLevelItem(blockLevel, co.x, co.y) : ""
            )
        );
    }

    function getLevelItem(
        uint256 level,
        uint32 x,
        uint32 y
    ) public pure returns (string memory) {
        bytes memory svgbytes = abi.encodePacked('<use width="');
        svgbytes = abi.encodePacked(
            svgbytes,
            '20.5" height="20.5" transform="translate(',
            Strings.toString(x + 13),
            " ",
            Strings.toString(y + 10)
        );

        return
            string(
                abi.encodePacked(
                    svgbytes,
                    ')" xlink:href="#Lv',
                    uint32(level).toString(),
                    '" />'
                )
            );
    }

    function getImage(
        string memory defs,
        string memory background,
        string memory blocks
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" ',
                    'xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 500 500">',
                    defs,
                    background,
                    blocks,
                    "</svg>"
                )
            );
    }

    function generateDefs(
        bytes memory ringbgcolor
    ) public pure returns (string memory svg) {
        svg = string(
            bytes.concat(
                abi.encodePacked(
                    "<defs><style>.c1 {font-size: 24px;}.c1,.c2 {font-family: ArialMT, Arial;isolation: isolate;}",
                    ".c2 {font-size: 14px;}.c3 {stroke-width: 0.25px;}.c3,.c4 {stroke: #000;stroke-miterlimit: 10;}",
                    ".c4 {fill: none;stroke-width: 0.5px;}.c5 {fill: #F2F2F2;}.c6 {fill: url(#background);}.b1 {fill: #fff;}</style>",
                    '<symbol id="Block" viewBox="0 0 46.188 40"><polygon class="c3" points="34.5688 .125 11.6192 .125 .1443 20 11.6192 39.875 34.5688 39.875 46.0437 20 34.5688 .125"/></symbol>',
                    '<symbol id="Lv5" viewBox="0 0 20.5 20.5"><circle class="c4" cx="10.25" cy="10.25" r="10"/></symbol>'
                    '<symbol id="Lv15" viewBox="0 0 20.5 20.5"><circle class="c4" cx="10.25" cy="10.25" r="10"/>',
                    '<g><circle cx="10.25" cy="10.25" r="4" /><animate attributeName="opacity" values="1;0;1" dur="3.85s" begin="0s" repeatCount="indefinite"/></g></symbol>'
                ),
                abi.encodePacked(
                    '<linearGradient id="background" x1="391.1842" y1="434.6524" x2="107.8509" y2="-56.0954" gradientTransform="translate(0 440.1141) scale(1 -1)" gradientUnits="userSpaceOnUse">',
                    '<stop offset=".03" stop-color="',
                    ringbgcolor,
                    '" stop-opacity=".6" /><stop offset=".5" stop-color="',
                    ringbgcolor,
                    '" /><stop offset=".96" stop-color="',
                    ringbgcolor,
                    '" stop-opacity=".2" /></linearGradient></defs>'
                )
            )
        );
    }

    function generateBackground(
        uint32 id,
        string memory coordinateStr
    ) public pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<g><rect class="c6" width="500" height="500" /><path class="c5" d="M490,10V490H10V10H490m10-10H0V500H500V0h0Z" />',
                '<text class="c1" transform="translate(30 46.4014)"><tspan>MOPN Land</tspan></text>',
                '<text class="c1" transform="translate(470 46.4014)" text-anchor="end"><tspan>#',
                id.toString(),
                '</tspan></text><text class="c2" transform="translate(470 475.4542)" text-anchor="end"><tspan>',
                coordinateStr,
                "</tspan></text></g>"
            )
        );
    }

    function generateBlocks(
        NFTSVG.tileData[] memory tileDatas
    ) public pure returns (string memory svg) {
        bytes memory output;
        uint32 ringNum = 0;
        uint32 ringPos = 1;
        uint32 cx = 226;
        uint32 cxdecimal = 906;
        uint32 cy = 230;
        coordinate memory co = coordinate(226, 906, 230);

        for (uint256 i = 0; i < tileDatas.length; i++) {
            output = abi.encodePacked(
                output,
                getBlock(co, tileDatas[i].tileMTAW, tileDatas[i].color)
            );

            if (ringPos >= ringNum * 6) {
                ringPos = 1;
                ringNum++;
                if (ringNum > 5) {
                    break;
                }
                co.x = cx;
                co.xdecimal = cxdecimal;
                co.y = cy - 40 * ringNum;
            } else {
                uint32 side = uint32(Math.ceilDiv(ringPos, ringNum));
                if (side == 1) {
                    co.xdecimal += 641;
                    if (co.xdecimal > 1000) {
                        co.x += 35;
                        co.xdecimal -= 1000;
                    } else {
                        co.x += 34;
                    }
                    co.y += 20;
                } else if (side == 2) {
                    co.y += 40;
                } else if (side == 3) {
                    if (co.xdecimal < 641) {
                        co.xdecimal += 359;
                        co.x -= 35;
                    } else {
                        co.xdecimal -= 641;
                        co.x -= 34;
                    }
                    co.y += 20;
                } else if (side == 4) {
                    if (co.xdecimal < 641) {
                        co.xdecimal += 359;
                        co.x -= 35;
                    } else {
                        co.xdecimal -= 641;
                        co.x -= 34;
                    }
                    co.y -= 20;
                } else if (side == 5) {
                    co.y -= 40;
                } else if (side == 6) {
                    co.xdecimal += 641;
                    if (co.xdecimal > 1000) {
                        co.x += 35;
                        co.xdecimal -= 1000;
                    } else {
                        co.x += 34;
                    }
                    co.y -= 20;
                }
                ringPos++;
            }
        }

        svg = string(abi.encodePacked("<g>", output, "</g>"));
    }

    function COIDToColor(uint256 COID) public pure returns (string memory) {
        uint256 i = 5;
        uint256 batch = 4096;
        uint256 step = 4096;
        uint256 h;
        uint256 s;
        uint256 l;
        while (true) {
            if (COID < step) {
                COID = (COID % 40) * (batch / 40) + (COID / 40);
                uint256 k = 2 ** (i - 1);
                uint256 v = COID - (step - batch);
                uint256 ht = (v / (k * k));
                h = ((360 / k) * (ht * 2 + 1)) / 2;
                v = v - ht * (k * k);
                uint256 st = (v / k);
                s = 100 - ((45 / k) * (st * 2 + 1)) / 2;
                uint256 lt = v - st * k;
                l = 50 + ((30 / k) * (lt * 2 + 1)) / 2;
                break;
            }
            batch = 8 ** i;
            step += batch;
            i++;
        }

        return
            string(
                abi.encodePacked(
                    "hsl(",
                    Strings.toString(h),
                    ", ",
                    Strings.toString(s),
                    "%, ",
                    Strings.toString(l),
                    "%)"
                )
            );
    }
}
