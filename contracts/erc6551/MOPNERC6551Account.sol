// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./interfaces/IMOPNERC6551Account.sol";
import "../interfaces/IMOPN.sol";
import "../interfaces/IMOPNGovernance.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./lib/ERC6551AccountLib.sol";

interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

error NotAuthorized();

contract MOPNERC6551Account is
    IERC165,
    IERC1271,
    IERC1155Receiver,
    IMOPNERC6551Account
{
    event AccountRent(address to, uint256 expiredAt);

    address private constant delegatecash =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    uint256 private _nonce;

    address private immutable governance;

    /**
     * @dev uint32 endtime + uint160 address
     */
    uint256 private rentData;

    mapping(address => uint256) private rentPermits;

    modifier onlyProxy() {
        if (msg.sender != IMOPNGovernance(governance).ERC6551AccountHelper())
            revert NotAuthorized();
        _;
    }

    constructor(address governance_) {
        governance = governance_;
    }

    receive() external payable {}

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result) {
        require(isOwner(msg.sender), "Not token owner");

        _incrementNonce();

        return _call(to, value, data);
    }

    function executeProxyCall(
        address to,
        uint256 value,
        bytes calldata data,
        address msgsender
    ) external payable onlyProxy returns (bytes memory result) {
        require(isOwner(msgsender), "Not token owner");

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
        if (block.timestamp < getRentEndTime()) {
            return getRentOwner();
        }
        return nftowner();
    }

    function nftowner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function isOwner(address caller) public view returns (bool) {
        if (caller == owner()) return true;
        if (caller == address(this)) return true;
        (, address tokenContract, uint256 tokenId) = this.token();
        return
            IDelegationRegistry(delegatecash).checkDelegateForToken(
                caller,
                owner(),
                tokenContract,
                tokenId
            );
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

    /// @dev Allows ERC-1155 tokens to be received. This function can be overriden.
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @dev Allows ERC-1155 token batches to be received. This function can be overriden.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function getRentEndTime() public view returns (uint256) {
        return rentData >> 160;
    }

    function getRentOwner() public view returns (address) {
        return address(uint160(rentData));
    }

    function rentPermit(address to, uint256 timeRange) public {
        require(isOwner(msg.sender), "not token owner");

        rentPermits[to] = timeRange;
    }

    function rentExecute(address to, uint256 timeRange) public {
        if (
            !isOwner(msg.sender) && rentPermits[msg.sender] != type(uint256).max
        ) {
            require(
                rentPermits[msg.sender] >= timeRange,
                "insufficient rent permits"
            );
            rentPermits[msg.sender] -= timeRange;
        }
        rentData =
            ((block.timestamp + timeRange) << 160) |
            uint256(uint160(to));

        emit AccountRent(to, block.timestamp + timeRange);
    }
}
