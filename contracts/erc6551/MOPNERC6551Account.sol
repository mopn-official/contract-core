// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./interfaces/IMOPNERC6551Account.sol";
import "./interfaces/IERC6551AccountOwnerHosting.sol";
import "../interfaces/IMOPN.sol";
import "../interfaces/IMOPNGovernance.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./lib/ERC6551AccountLib.sol";

error NotAuthorized();

contract MOPNERC6551Account is
    IERC165,
    IERC1271,
    IERC721Receiver,
    IERC1155Receiver,
    IMOPNERC6551Account
{
    event OwnerHostingSet(address ownerHosting, address oldOwnerHosting);

    event OwnerTransfer(address ownerHosting, address to, uint256 endBlock);

    uint256 private _nonce;

    address private immutable governance;

    /// uint8 initialize + uint160 ownerHosting
    uint256 public ownerHostingData;

    address public immutable defaultOwnerHosting;

    constructor(address governance_, address defaultOwnerHosting_) {
        governance = governance_;
        defaultOwnerHosting = defaultOwnerHosting_;
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
    ) external payable onlyHelper returns (bytes memory result) {
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
        require(to != ownerHosting(), "not allow low-level call ownerHosting");
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

    function ownerHosting() public view returns (address) {
        if (ownerHostingData == 0) return defaultOwnerHosting;
        return address(uint160(ownerHostingData));
    }

    function owner() public view returns (address owner_) {
        address ownerHosting_ = ownerHosting();
        if (ownerHosting_ != address(0))
            owner_ = IERC6551AccountOwnerHosting(ownerHosting_).owner(
                address(this)
            );

        if (owner_ == address(0)) owner_ = nftowner();
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
        return false;
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
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @dev Allows ERC-1155 token batches to be received. This function can be overriden.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setOwnerHosting(address ownerHosting_) public {
        address nftowner_ = nftowner();
        console.log("caller", msg.sender);
        require(
            msg.sender == nftowner_ ||
                (msg.sender == IMOPNGovernance(governance).ERC6551Registry() &&
                    tx.origin == nftowner_),
            "not nft owner"
        );
        address oldOwnerHosting = ownerHosting();
        if (oldOwnerHosting != address(0)) {
            IERC6551AccountOwnerHosting(oldOwnerHosting).beforeRevokeHosting();
        }
        ownerHostingData = (1 << 160) | uint256(uint160(ownerHosting_));
        emit OwnerHostingSet(ownerHosting_, oldOwnerHosting);
    }

    function hostingOwnerTransferNotify(address to, uint256 endBlock) public {
        require(ownerHosting() == msg.sender, "hostingOwner mismatch");
        emit OwnerTransfer(msg.sender, to, endBlock);
    }

    modifier onlyHelper() {
        if (msg.sender != IMOPNGovernance(governance).ERC6551AccountHelper())
            revert NotAuthorized();
        _;
    }
}
