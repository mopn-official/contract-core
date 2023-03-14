// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IMOPNToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function transferOwnership(address newOwner) external;
}
