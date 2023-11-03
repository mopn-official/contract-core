// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./interfaces/IMOPNERC6551Account.sol";
import "../interfaces/IMOPN.sol";
import "../interfaces/IMOPNGovernance.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./lib/ERC6551AccountLib.sol";

error NotAuthorized();

interface ICryptoPunks {
    function punkIndexToAddress(
        uint index
    ) external view returns (address owner);
}

contract MOPNERC6551Account is
    IERC165,
    IERC1271,
    IERC721Receiver,
    IERC1155Receiver,
    IMOPNERC6551Account,
    Multicall
{
    event OwnershipModeChange(uint8 ownershipMode, uint8 oldOwnershipMode);

    event OwnerTransfer(address to, uint40 endBlock);

    address public immutable governance;

    address public immutable ownershipRentalContract;

    uint8 public ownershipMode;

    uint40 public rentEndBlock;

    address public renter;

    uint256 public state;

    constructor(address governance_, address ownershipRentalContract_) {
        governance = governance_;
        ownershipRentalContract = ownershipRentalContract_;
    }

    receive() external payable {}

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation
    ) external payable returns (bytes memory result) {
        require(isOwner(msg.sender), "Not token owner");
        require(operation == 0, "Only call operations are supported");
        ++state;
        return _call(to, value, data);
    }

    function executeProxy(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation,
        address msgsender
    ) external payable onlyHelper returns (bytes memory result) {
        require(isOwner(msgsender), "Not token owner");
        require(operation == 0, "Only call operations are supported");
        ++state;
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
        if (block.number < rentEndBlock) {
            return renter;
        }

        return nftowner();
    }

    function nftowner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .token();
        if (chainId != block.chainid) return address(0);

        if (tokenContract == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
            return ICryptoPunks(tokenContract).punkIndexToAddress(tokenId);
        } else {
            return IERC721(tokenContract).ownerOf(tokenId);
        }
    }

    function isOwner(address caller) public view returns (bool) {
        if (caller == owner()) return true;
        if (caller == address(this)) return true;
        return false;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId);
    }

    function isValidSigner(
        address signer,
        bytes calldata
    ) external view returns (bytes4) {
        if (isOwner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
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

    function setOwnershipMode(uint8 ownershipMode_) public {
        address nftowner_ = nftowner();
        require(
            msg.sender == nftowner_ ||
                (msg.sender == IMOPNGovernance(governance).ERC6551Registry() &&
                    tx.origin == nftowner_),
            "not nft owner"
        );
        require(ownershipMode != ownershipMode_, "mode not change");
        require(rentEndBlock < block.number, "rent not finish");

        emit OwnershipModeChange(ownershipMode_, ownershipMode);
        ownershipMode = ownershipMode_;
        rentEndBlock = 0;
        renter = address(0);
    }

    function ownerTransferTo(address to, uint40 endBlock) public {
        if (ownershipMode == 0) {
            require(msg.sender == nftowner(), "not allowed");
        } else if (ownershipMode == 1) {
            require(msg.sender == ownershipRentalContract, "not allowed");
        } else {
            require(false, "OwnershipMode not supported transfer");
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
