// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNRentalProxy is ERC1967Proxy, Ownable {
    constructor(
        address implementation,
        bytes memory _data,
        address initialOwner
    ) payable Ownable(initialOwner) ERC1967Proxy(implementation, _data) {}

    function upgradeTo(address implementation_) public onlyOwner {
        require(implementation_ != _implementation(), "same Implementation");
        ERC1967Utils.upgradeToAndCall(implementation_, "");
    }

    receive() external payable {}
}
