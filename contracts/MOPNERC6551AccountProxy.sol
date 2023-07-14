// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IMOPNGovernance.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./erc6551/interfaces/IMOPNERC6551Account.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/**
 * @title A smart contract account owned by a single ERC721 token
 */
contract MOPNERC6551AccountProxy is Multicall {
    IMOPNGovernance public governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        return
            IERC6551Registry(governance.erc6551Registry()).createAccount(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt,
                initData
            );
    }

    function computeAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address) {
        return
            IERC6551Registry(governance.erc6551Registry()).account(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt
            );
    }

    function checkAccountExist() external view returns (bool) {}

    /// @dev executes a low-level call against an account if the caller is authorized to make calls
    function proxyCall(
        address account,
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory) {
        return
            IMOPNERC6551Account(payable(account)).executeProxyCall(
                to,
                value,
                data,
                msg.sender
            );
    }
}
