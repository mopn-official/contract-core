// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

contract Props is ERC1155Upgradeable {
    function useTo(uint256 propId, uint256 amount, uint256 x, uint256 y) public {}
}
