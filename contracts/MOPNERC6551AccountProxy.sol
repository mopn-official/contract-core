// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IMOPNGovernance.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "./erc6551/lib/ERC6551AccountLib.sol";

contract MOPNERC6551AccountProxy is Proxy, ERC1967Upgrade {
    address immutable governance;

    constructor(address governance_) {
        governance = governance_;
    }

    function initialize() external {
        address implementation_ = _implementation();

        if (implementation_ == address(0)) {
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

    function _implementation() internal view override returns (address) {
        return ERC1967Upgrade._getImplementation();
    }

    function implementation() public view returns (address) {
        return _implementation();
    }
}
