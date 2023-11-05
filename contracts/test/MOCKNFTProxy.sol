// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "../interfaces/IMOPNGovernance.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MOCKNFTProxy is ERC1967Proxy {
    address public immutable defaultImplementation;

    constructor(
        address defaultImplementation_,
        bytes memory _data
    ) payable ERC1967Proxy(defaultImplementation_, _data) {
        defaultImplementation = defaultImplementation_;
    }

    function upgradeTo(address implementation_) public {
        require(msg.sender == owner(), "only owner can upgrade");
        require(implementation_ != _implementation(), "same Implementation");
        ERC1967Utils.upgradeToAndCall(implementation_, "");
    }

    function _implementation()
        internal
        view
        override
        returns (address implementation_)
    {
        implementation_ = ERC1967Utils.getImplementation();
        if (implementation_ == address(0))
            implementation_ = defaultImplementation;
    }

    function implementation() public view returns (address) {
        return _implementation();
    }

    receive() external payable {}

    function owner() internal view returns (address) {
        bytes memory footer = new bytes(0x20);

        assembly {
            // copy 0x20 bytes from end of footer
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x6d)
        }

        return abi.decode(footer, (address));
    }
}
