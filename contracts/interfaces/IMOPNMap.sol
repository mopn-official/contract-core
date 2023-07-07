// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPNMap {
    function accountSet(
        address account,
        uint32 tileCoordinate,
        uint32 LandId
    ) external;

    function accountRemove(
        uint32 tileCoordinate,
        address excludeAccount
    ) external returns (address payable);

    function getTileAccount(
        uint32 tileCoordinate
    ) external view returns (address payable);

    function getTileCollection(
        uint32 tileCoordinate
    ) external view returns (address);

    function getTileLandId(
        uint32 tileCoordinate
    ) external view returns (uint32);
}
