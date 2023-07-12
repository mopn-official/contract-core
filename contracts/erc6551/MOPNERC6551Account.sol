// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";
import "./interfaces/IMOPNERC6551Account.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./lib/ERC6551AccountLib.sol";

error NotAuthorized();

contract MOPNERC6551Account is IERC165, IERC1271, IMOPNERC6551Account {
    uint256 _nonce;

    address _proxy;

    modifier onlyProxy() {
        if (msg.sender != _proxy) revert NotAuthorized();
        _;
    }

    constructor(address proxy) {
        _proxy = proxy;
    }

    receive() external payable {}

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result) {
        require(msg.sender == owner(), "Not token owner");

        _incrementNonce();

        return _call(to, value, data);
    }

    function executeProxyCall(
        address to,
        uint256 value,
        bytes calldata data,
        address msgsender
    ) external payable returns (bytes memory result) {
        require(msgsender == owner(), "Not token owner");

        _incrementNonce();

        return _call(to, value, data);
    }

    /// @dev Executes a low-level call
    function _call(
        address to,
        uint256 value,
        bytes calldata data
    ) internal returns (bytes memory result) {
        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        return ERC6551AccountLib.token();
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    function nonce() external view override returns (uint256) {
        return _nonce;
    }

    function _incrementNonce() internal {
        _nonce++;
    }
}
