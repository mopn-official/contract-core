// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC6551Account.sol";

/// @dev the ERC-165 identifier for this interface is `0xeff4d378`
interface IMOPNERC6551Account is IERC6551Account {
    function executeProxyCall(
        address to,
        uint256 value,
        bytes calldata data,
        address msgsender
    ) external payable returns (bytes memory);

    function isOwner(address caller) external view returns (bool);

    function nftowner() external view returns (address);

    function ownershipHostingType() external view returns (uint8);

    function ownerTransferTo(address to, uint40 endBlock) external;
}
