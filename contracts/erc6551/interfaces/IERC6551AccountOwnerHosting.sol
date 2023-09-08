// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC6551AccountOwnerHosting {
    function owner(address account) external view returns (address);

    function beforeRevokeHosting() external;

    function revokeHostingLockState(
        address account
    ) external view returns (bool);
}
