// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTWarrant is Multicall, Ownable {
    struct AuthorizedNFTInfo {
        address owner;
        address authorizedUser;
        uint256 expiredAt;
    }

    mapping(address => mapping(uint256 => mapping(address => AuthorizedNFTInfo)))
        public warrants;

    function ownerOf(
        address appContract,
        address collectionContract,
        uint256 tokenId
    ) public view returns (address owner) {
        require(
            IERC165(collectionContract).supportsInterface(
                type(IERC721).interfaceId
            ),
            "not a erc721 compatible nft"
        );
        if (
            block.timestamp <
            warrants[collectionContract][tokenId][address(0)].expiredAt
        ) {
            return
                warrants[collectionContract][tokenId][address(0)]
                    .authorizedUser;
        } else if (
            block.timestamp <
            warrants[collectionContract][tokenId][appContract].expiredAt
        ) {
            return
                warrants[collectionContract][tokenId][appContract]
                    .authorizedUser;
        }
        return IERC721(collectionContract).ownerOf(tokenId);
    }

    function getAuthorizedNFTInfo(
        address appContract,
        address collectionContract,
        uint256 tokenId
    ) public view returns (AuthorizedNFTInfo memory aInfo) {
        require(
            IERC165(collectionContract).supportsInterface(
                type(IERC721).interfaceId
            ),
            "not a erc721 compatible nft"
        );
        if (
            block.timestamp <
            warrants[collectionContract][tokenId][address(0)].expiredAt
        ) {
            aInfo = warrants[collectionContract][tokenId][address(0)];
        } else if (
            block.timestamp <
            warrants[collectionContract][tokenId][appContract].expiredAt
        ) {
            aInfo = warrants[collectionContract][tokenId][appContract];
        }
    }

    function registerProxy(
        address appContract,
        address collectionContract,
        uint256 tokenId,
        address authorizedUser,
        uint256 expiredAt
    ) public {
        require(
            IERC721(collectionContract).ownerOf(tokenId) == msg.sender,
            "not your nft"
        );

        if (appContract != address(0)) {
            require(
                block.timestamp >
                    warrants[collectionContract][tokenId][address(0)].expiredAt,
                "to all warrant exist"
            );
        }
        _requireExpired(
            appContract,
            collectionContract,
            tokenId,
            authorizedUser,
            expiredAt
        );

        warrants[collectionContract][tokenId][appContract].owner = msg.sender;
        warrants[collectionContract][tokenId][appContract]
            .authorizedUser = authorizedUser;
        warrants[collectionContract][tokenId][appContract]
            .expiredAt = expiredAt;
    }

    function _requireExpired(
        address appContract,
        address collectionContract,
        uint256 tokenId,
        address authorizedUser,
        uint256 expiredAt
    ) internal view {
        if (
            authorizedUser !=
            warrants[collectionContract][tokenId][appContract].authorizedUser
        ) {
            require(
                block.timestamp >
                    warrants[collectionContract][tokenId][appContract]
                        .expiredAt,
                "previous warrant not expired"
            );
        } else {
            require(
                expiredAt >
                    warrants[collectionContract][tokenId][appContract]
                        .expiredAt,
                "only allowed extend if previous warrant not expired"
            );
        }
    }
}
