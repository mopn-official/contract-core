// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IMOPN.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "./lib/ERC6551AccountLib.sol";

contract MOPNERC6551AccountProxy is Proxy {
    address public immutable defaultImplementation;

    constructor(address defaultImplementation_) {
        defaultImplementation = defaultImplementation_;
    }

    function upgradeTo(address implementation_, bytes memory data) public {
        (uint256 chainId, address tokenContract, uint256 tokenId) = ERC6551AccountLib.token();

        require(chainId == block.chainid, "chainId mismatch");
        require(msg.sender == IERC721(tokenContract).ownerOf(tokenId), "only owner can upgrade");
        require(implementation_ != _implementation(), "same Implementation");

        ERC1967Utils.upgradeToAndCall(implementation_, data);
    }

    function _implementation() internal view override returns (address implementation_) {
        implementation_ = ERC1967Utils.getImplementation();
        if (implementation_ == address(0)) implementation_ = defaultImplementation;
    }

    function implementation() public view returns (address) {
        return _implementation();
    }

    receive() external payable virtual {
        _fallback();
    }
}
