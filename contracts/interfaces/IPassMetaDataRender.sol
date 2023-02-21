// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPassMetaDataRender {
    function constructTokenURI(
        uint256 PassId
    ) external view returns (string memory);
}
