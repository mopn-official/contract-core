// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface ILand is IERC721 {
    function safeMint(address to) external;

    function nextTokenId() external view returns (uint256);
}
