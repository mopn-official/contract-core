// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNRentalProxy is Proxy, ERC1967Upgrade, Ownable {
    constructor(address defaultImplementation_) {
        ERC1967Upgrade._upgradeTo(defaultImplementation_);
    }

    function upgradeTo(address implementation_) public onlyOwner {
        require(implementation_ != _implementation(), "same Implementation");
        ERC1967Upgrade._upgradeTo(implementation_);
    }

    function _implementation()
        internal
        view
        override
        returns (address implementation_)
    {
        implementation_ = ERC1967Upgrade._getImplementation();
    }

    function implementation() public view returns (address) {
        return _implementation();
    }
}
