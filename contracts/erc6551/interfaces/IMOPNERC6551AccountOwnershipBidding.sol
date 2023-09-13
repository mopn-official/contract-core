// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMOPNERC6551AccountOwnershipBidding {
    function bidNFTTo(
        address collectionAddress,
        uint256 tokenId,
        address to
    ) external payable returns (address account);

    function bidAccountTo(address account, address to) external payable;

    function cancelOwnershipBid() external;
}
