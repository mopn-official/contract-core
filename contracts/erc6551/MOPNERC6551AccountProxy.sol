// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "../interfaces/IMOPNGovernance.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "./lib/ERC6551AccountLib.sol";

contract MOPNERC6551AccountProxy is Proxy, ERC1967Upgrade {
    address public immutable governance;
    address public immutable defaultImplementation;

    constructor(address governance_, address defaultImplementation_) {
        governance = governance_;
        defaultImplementation = defaultImplementation_;
    }

    function initialize() external {
        if (ERC1967Upgrade._getImplementation() == address(0)) {
            ERC1967Upgrade._upgradeTo(
                IMOPNGovernance(governance)
                    .getDefault6551AccountImplementation()
            );
        }
    }

    function upgradeTo(address implementation_) public {
        (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        ) = ERC6551AccountLib.token();

        require(chainId == block.chainid, "chainId mismatch");
        require(
            msg.sender == IERC721(tokenContract).ownerOf(tokenId),
            "only owner can upgrade"
        );
        require(implementation_ != _implementation(), "same Implementation");
        require(
            IMOPNGovernance(governance).checkImplementationExist(
                implementation_
            ),
            "none authorized implementation"
        );

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
