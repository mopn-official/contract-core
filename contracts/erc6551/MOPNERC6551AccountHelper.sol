// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPNERC6551Account.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MOPNERC6551AccountHelper is Multicall {
    address public immutable ERC6551Registry;

    constructor(address ERC6551Registry_) {
        ERC6551Registry = ERC6551Registry_;
    }

    function createAccount(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId) external returns (address) {
        return IERC6551Registry(ERC6551Registry).createAccount(implementation, salt, chainId, tokenContract, tokenId);
    }

    function computeAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public view returns (address) {
        return IERC6551Registry(ERC6551Registry).account(implementation, salt, chainId, tokenContract, tokenId);
    }

    function checkAccountExist(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (bool exist, address _account) {
        _account = computeAccount(implementation, salt, chainId, tokenContract, tokenId);
        if (_account.code.length != 0) return (true, _account);
        return (false, _account);
    }

    /// @dev executes a low-level call against an account if the caller is authorized to make calls
    function executeProxy(address account, address to, uint256 value, bytes calldata data, uint256 operation) public payable returns (bytes memory) {
        return IMOPNERC6551Account(payable(account)).executeProxy(to, value, data, operation, msg.sender);
    }
}
