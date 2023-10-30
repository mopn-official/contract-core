// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MOCKWETH is ERC20Burnable {
    constructor() ERC20("MOPN MOCK WETH", "MMWETH") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
