// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IBomb is IERC1155 {
    function burn(address from, uint256 id, uint256 amount) external;
}
