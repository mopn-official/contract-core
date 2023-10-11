// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC6551Account.sol";
import "./IERC6551Executable.sol";

interface IMOPNERC6551Account is IERC6551Account, IERC6551Executable {
    function executeProxy(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation,
        address msgsender
    ) external payable returns (bytes memory);

    function isOwner(address caller) external view returns (bool);

    function owner() external view returns (address);

    function nftowner() external view returns (address);

    function ownershipMode() external view returns (uint8);

    function ownerTransferTo(address to, uint40 endBlock) external;

    function renter() external view returns (address);

    function rentEndBlock() external view returns (uint40);
}
