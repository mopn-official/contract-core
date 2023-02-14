// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

library TileMath {
    error TileCoordinateError();

    function check(uint32 tileCoordinate) public pure {
        uint32[3] memory coodinateArr = coordinateIntToArr(tileCoordinate);
        if (coodinateArr[0] + coodinateArr[1] + coodinateArr[2] != 3000) {
            revert TileCoordinateError();
        }
    }

    function PassRingNum(uint32 PassId) public pure returns (uint32 n) {
        n = uint32((Math.sqrt(9 + 12 * (uint256(PassId) - 1)) - 3) / (6));
        if ((3 * n * n + 3 * n + 1) == PassId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function PassRingPos(uint32 PassId) public pure returns (uint32) {
        uint32 ringNum = PassRingNum(PassId) - 1;
        return PassId - (3 * ringNum * ringNum + 3 * ringNum + 1);
    }

    function PassRingStartCenterTile(
        uint32 PassIdRingNum_
    ) public pure returns (uint32) {
        return
            (1000 - PassIdRingNum_ * 5) * 10000 + (1000 + PassIdRingNum_ * 11);
    }

    function PassCenterTile(
        uint32 PassId
    ) public pure returns (uint32 tileCoordinate) {
        if (PassId == 1) {
            return 10001000;
        }

        uint32 PassIdRingNum_ = PassRingNum(PassId);

        uint32[3] memory startTile = coordinateIntToArr(
            PassRingStartCenterTile(PassIdRingNum_)
        );

        uint32 PassIdRingPos_ = PassRingPos(PassId);

        uint32 side = uint32(Math.ceilDiv(PassIdRingPos_, PassIdRingNum_));

        uint32 sidepos = 0;
        if (PassIdRingNum_ > 1) {
            sidepos = (PassIdRingPos_ - 1) % PassIdRingNum_;
        }
        if (side == 1) {
            tileCoordinate = (startTile[0] + sidepos * 11) * 10000;
            tileCoordinate += startTile[1] - sidepos * 6;
        } else if (side == 2) {
            tileCoordinate = (2000 - startTile[2] + sidepos * 5) * 10000;
            tileCoordinate += 2000 - startTile[0] - sidepos * 11;
        } else if (side == 3) {
            tileCoordinate = (startTile[1] - sidepos * 6) * 10000;
            tileCoordinate += startTile[2] - sidepos * 5;
        } else if (side == 4) {
            tileCoordinate = (2000 - startTile[0] - sidepos * 11) * 10000;
            tileCoordinate += 2000 - startTile[1] + sidepos * 6;
        } else if (side == 5) {
            tileCoordinate = (startTile[2] - sidepos * 5) * 10000;
            tileCoordinate += startTile[0] + sidepos * 11;
        } else if (side == 6) {
            tileCoordinate = (2000 - startTile[1] + sidepos * 6) * 10000;
            tileCoordinate += 2000 - startTile[2] + sidepos * 5;
        }
    }

    function PassTileRange(
        uint32 tileCoordinate
    ) public pure returns (uint32[] memory, uint32[] memory) {
        uint32[] memory xrange = new uint32[](11);
        uint32[] memory yrange = new uint32[](11);
        uint32[3] memory blockArr = coordinateIntToArr(tileCoordinate);
        for (uint256 i = 0; i < 11; i++) {
            xrange[i] = blockArr[0] + uint32(i) - 5;
            yrange[i] = blockArr[1] + uint32(i) - 5;
        }
        return (xrange, yrange);
    }

    function getPassTilesEAW(
        uint32 PassId
    ) public pure returns (uint256[] memory) {
        uint32 tileCoordinate = PassCenterTile(PassId);
        uint256[] memory TilesEAW = new uint256[](91);
        TilesEAW[0] = getTileEAW(tileCoordinate);
        for (uint256 i = 1; i <= 5; i++) {
            tileCoordinate++;
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    TilesEAW[preringblocks + j * i + k + 1] = getTileEAW(
                        tileCoordinate
                    );
                    tileCoordinate = neighbor(tileCoordinate, j);
                }
            }
        }
        return TilesEAW;
    }

    function getTileEAW(uint32 tileCoordinate) public pure returns (uint256) {
        if ((tileCoordinate / 10000) % 10 == 0) {
            if (tileCoordinate % 10 == 0) {
                return 15;
            }
            return 5;
        } else if (tileCoordinate % 10 == 0) {
            return 5;
        }
        return 1;
    }

    function coordinateIntToArr(
        uint32 tileCoordinate
    ) public pure returns (uint32[3] memory coordinateArr) {
        coordinateArr[0] = tileCoordinate / 10000;
        coordinateArr[1] = tileCoordinate % 10000;
        coordinateArr[2] = 3000 - (coordinateArr[0] + coordinateArr[1]);
    }

    function spiralRingTiles(
        uint32 tileCoordinate,
        uint256 radius
    ) public pure returns (uint32[] memory) {
        uint256 blockNum = 3 * radius * radius + 3 * radius;
        uint32[] memory blocks = new uint32[](blockNum);
        blocks[0] = tileCoordinate;
        for (uint256 i = 1; i <= radius; i++) {
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            tileCoordinate++;
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    blocks[preringblocks + j * i + k + 1] = tileCoordinate;
                    tileCoordinate = neighbor(tileCoordinate, j);
                }
            }
        }
        return blocks;
    }

    function ringTiles(
        uint32 tileCoordinate,
        uint256 radius
    ) public pure returns (uint32[] memory) {
        uint256 blockNum = 6 * radius;
        uint32[] memory blocks = new uint32[](blockNum);

        blocks[0] = tileCoordinate;
        tileCoordinate += uint32(radius);
        for (uint256 j = 0; j < 6; j++) {
            for (uint256 k = 0; k < radius; k++) {
                blocks[j * radius + k + 1] = tileCoordinate;
                tileCoordinate = neighbor(tileCoordinate, j);
            }
        }
        return blocks;
    }

    function tileSpheres(
        uint32 tileCoordinate
    ) public pure returns (uint32[] memory) {
        uint32[] memory blocks = new uint32[](7);
        blocks[0] = tileCoordinate;
        tileCoordinate++;
        for (uint256 i = 1; i < 7; i++) {
            blocks[i] = tileCoordinate;
            tileCoordinate = neighbor(tileCoordinate, i);
        }
        return blocks;
    }

    function direction(uint256 direction_) public pure returns (int32) {
        if (direction_ == 0) {
            return 9999;
        } else if (direction_ == 1) {
            return -1;
        } else if (direction_ == 2) {
            return -10000;
        } else if (direction_ == 3) {
            return -9999;
        } else if (direction_ == 4) {
            return 1;
        } else if (direction_ == 5) {
            return 10000;
        } else {
            return 0;
        }
    }

    function neighbor(
        uint32 tileCoordinate,
        uint256 direction_
    ) public pure returns (uint32) {
        return uint32(int32(tileCoordinate) + direction(direction_));
    }

    function distance(uint32 a, uint32 b) public pure returns (uint32 d) {
        uint32[3] memory aarr = coordinateIntToArr(a);
        uint32[3] memory barr = coordinateIntToArr(b);
        for (uint256 i = 0; i < 3; i++) {
            d += aarr[i] > barr[i] ? aarr[i] - barr[i] : barr[i] - aarr[i];
        }

        return d / 2;
    }
}
