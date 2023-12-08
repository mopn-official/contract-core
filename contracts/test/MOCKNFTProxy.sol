// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "../interfaces/IMOPNGovernance.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

contract MOCKNFTProxy is Proxy, ERC1967Upgrade {
    error InitializationFailed();

    address public immutable defaultImplementation;
    address public immutable owner;

    constructor(address defaultImplementation_, address owner_) {
        defaultImplementation = defaultImplementation_;
        owner = owner_;
    }

    function upgradeTo(address implementation_) public {
        require(msg.sender == owner, "only owner can upgrade");
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
        if (implementation_ == address(0))
            implementation_ = defaultImplementation;
    }

    function implementation() public view returns (address) {
        return _implementation();
    }
}
