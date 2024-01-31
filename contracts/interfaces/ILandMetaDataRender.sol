// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILandMetaDataRender {
    function constructTokenURI(
        uint256 LandId
    ) external view returns (string memory);
}
