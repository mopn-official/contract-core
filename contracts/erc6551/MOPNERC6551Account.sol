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
    event OwnerHostingSet(uint8 ownerHostingType, uint8 oldOwnerHostingType);

    event OwnerTransfer(address to, uint40 endBlock);

    address public immutable governance;

    address public immutable ownershipBiddingContract;

    address public immutable ownershipRentalContract;

    uint48 private _nonce;

    uint8 public ownershipHostingType;

    uint40 public rentEndBlock;

    address public renter;

    constructor(
        address governance_,
        address ownershipBiddingContract_,
        address ownershipRentalContract_
    ) {
        governance = governance_;
        ownershipBiddingContract = ownershipBiddingContract_;
        ownershipRentalContract = ownershipRentalContract_;
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
        require(
            to != ownershipBiddingContract && to != ownershipRentalContract,
            "not allow low-level call to rentHosting"
        );
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
        if (block.number < rentEndBlock) {
            return renter;
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

    function setOwnershipHostingType(uint8 ownershipHostingType_) public {
        address nftowner_ = nftowner();
        require(
            msg.sender == nftowner_ ||
                (msg.sender == IMOPNGovernance(governance).ERC6551Registry() &&
                    tx.origin == nftowner_),
            "not nft owner"
        );
        require(rentEndBlock < block.number, "rent not finish");
        emit OwnerHostingSet(ownershipHostingType_, ownershipHostingType);
        ownershipHostingType = ownershipHostingType_;
    }

    function ownerTransferTo(address to, uint40 endBlock) public {
        if (ownershipHostingType == 1) {
            require(msg.sender == ownershipBiddingContract, "not allowed");
        } else if (ownershipHostingType == 2) {
            require(msg.sender == ownershipRentalContract, "not allowed");
        } else {
            require(msg.sender == nftowner(), "not allowed");
        }
        renter = to;
        rentEndBlock = endBlock;
        emit OwnerTransfer(to, endBlock);
    }

    modifier onlyHelper() {
        if (msg.sender != IMOPNGovernance(governance).ERC6551AccountHelper())
            revert NotAuthorized();
        _;
    }
}
