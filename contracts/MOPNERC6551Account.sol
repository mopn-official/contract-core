// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./erc6551/interfaces/IMOPNERC6551Account.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./erc6551/lib/ERC6551AccountLib.sol";

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
    address public constant delegatecash =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    uint256 _nonce;

    address public immutable governance;

    modifier onlyProxy() {
        if (msg.sender != IMOPNGovernance(governance).mopnErc6551AccountProxy())
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
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function isOwner(address caller) public view returns (bool) {
        if (caller == owner()) return true;
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
        address operator,
        address,
        uint256 id,
        uint256,
        bytes calldata data
    ) public override returns (bytes4) {
        if (
            data.length > 0 &&
            msg.sender == IMOPNGovernance(governance).bombContract() &&
            id == 1 &&
            isOwner(operator)
        ) {
            uint256 coordinate = abi.decode(data, (uint256));
            IMOPN(IMOPNGovernance(governance).mopnContract()).bomb(
                uint32(coordinate)
            );
        }
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @dev Allows ERC-1155 token batches to be received. This function can be overriden.
    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory data
    ) public override returns (bytes4) {
        for (uint256 i = 0; i < ids.length; i++) {
            if (
                ids[i] == 1 &&
                data.length > 0 &&
                msg.sender == IMOPNGovernance(governance).bombContract() &&
                isOwner(operator)
            ) {
                uint256 coordinate = abi.decode(data, (uint256));
                IMOPN(IMOPNGovernance(governance).mopnContract()).bomb(
                    uint32(coordinate)
                );
            }
        }
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function rentPremit(address to, uint256 timeRange) public {}

    function rentExecute(address to, uint256 timeRange) public {}
}
