// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNMap.sol";
import "./interfaces/IMOPNMiningData.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/

/// @title MOPN Contract
/// @author Cyanface <cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract MOPN is IMOPN, Multicall, Ownable {
    using TileMath for uint32;

    IMOPNGovernance public governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function getNFTAccount(
        NFTParams calldata params
    ) public view returns (address payable) {
        return
            payable(
                IERC6551Registry(governance.erc6551Registry()).account(
                    governance.erc6551AccountImplementation(),
                    governance.chainId(),
                    params.collectionAddress,
                    params.tokenId,
                    1
                )
            );
    }

    function getNFTAccountOwner(
        NFTParams calldata params
    ) public view returns (address) {
        address payable account = getNFTAccount(params);
        return IERC6551Account(account).owner();
    }

    /**
     * @notice get the original owner of a NFT
     * MOPN Avatar support hot wallet protocol https://delegate.cash/ and https://warm.xyz/ to verify your NFTs
     * @param params NFT collection Contract Address and tokenId
     * @param operator operator
     * @return owner nft owner or nft delegate hot wallet
     */
    function ownerOf(
        NFTParams calldata params,
        address operator
    ) public view returns (address owner) {
        address payable account = getNFTAccount(params);
        if (account == operator) {
            return operator;
        }
        address accountowner = IERC6551Account(account).owner();
        if (accountowner == operator) {
            return operator;
        }
        if (
            IDelegationRegistry(governance.delegateCashContract())
                .checkDelegateForToken(
                    operator,
                    account,
                    params.collectionAddress,
                    params.tokenId
                )
        ) {
            return operator;
        }
        if (
            IDelegationRegistry(governance.delegateCashContract())
                .checkDelegateForToken(
                    operator,
                    account,
                    params.collectionAddress,
                    params.tokenId
                )
        ) {
            return operator;
        }
        return account;
    }

    /**
     * @notice an on map avatar move to a new tile
     * @param params NFTParams
     */
    function moveTo(
        NFTParams calldata params,
        uint32 tileCoordinate,
        address payable linkedAccount,
        uint32 LandId
    ) public tileCheck(tileCoordinate) ownerCheck(params) {
        address payable account = getNFTAccount(params);
        IMOPNMiningData miningData = IMOPNMiningData(
            governance.miningDataContract()
        );
        if (miningData.getAccountPerNFTPointMinted(account) == 0) {
            emit NFTJoin(account, params.collectionAddress, params.tokenId);
        }
        linkCheck(account, linkedAccount, tileCoordinate);

        uint32 orgCoordinate = miningData.getAccountCoordinate(account);
        if (orgCoordinate > 0) {
            IMOPNMap(governance.mapContract()).accountRemove(
                orgCoordinate,
                address(0)
            );

            emit NFTMove(account, LandId, orgCoordinate, tileCoordinate);
        } else {
            emit NFTJumpIn(account, LandId, tileCoordinate);
        }

        IMOPNMap(governance.mapContract()).accountSet(
            account,
            tileCoordinate,
            LandId
        );

        miningData.setAccountCoordinate(account, tileCoordinate);
    }

    /**
     * @notice throw a bomb to a tile
     * @param params NFTParams
     */
    function bomb(
        NFTParams calldata params,
        uint32 tileCoordinate
    ) public tileCheck(tileCoordinate) ownerCheck(params) {
        address payable account = getNFTAccount(params);
        IMOPNMiningData miningData = IMOPNMiningData(
            governance.miningDataContract()
        );
        if (miningData.getAccountPerNFTPointMinted(account) == 0) {
            emit NFTJoin(account, params.collectionAddress, params.tokenId);
        }

        if (miningData.getAccountCoordinate(account) > 0) {
            IMOPNMiningData(governance.miningDataContract()).addNFTPoint(
                account,
                1
            );
        }

        governance.burnBomb(msg.sender, 1);

        address[] memory attackAccounts = new address[](7);
        uint32[] memory victimsCoordinates = new uint32[](7);
        uint32 orgTileCoordinate = tileCoordinate;

        for (uint256 i = 0; i < 7; i++) {
            address payable attackAccount = IMOPNMap(governance.mapContract())
                .accountRemove(tileCoordinate, account);

            if (attackAccount != address(0)) {
                miningData.setAccountCoordinate(attackAccount, 0);
                attackAccounts[i] = attackAccount;
                victimsCoordinates[i] = tileCoordinate;
            }

            if (i == 0) {
                tileCoordinate = tileCoordinate.neighbor(4);
            } else {
                tileCoordinate = tileCoordinate.neighbor(i - 1);
            }
        }

        emit BombUse(
            account,
            orgTileCoordinate,
            attackAccounts,
            victimsCoordinates
        );
    }

    /**
     * @notice check if this collection is in white list
     * @param collectionAddress collection contract address
     * @param additionalNFTPoints additional NFT Points
     * @param proofs collection whitelist proofs
     */
    function setCollectionAdditionalNFTPoints(
        address collectionAddress,
        uint256 additionalNFTPoints,
        bytes32[] memory proofs
    ) public {
        require(
            MerkleProof.verify(
                proofs,
                governance.whiteListRoot(),
                keccak256(
                    bytes.concat(
                        keccak256(
                            abi.encode(collectionAddress, additionalNFTPoints)
                        )
                    )
                )
            ),
            "collection additionalNFTPoints can't verify"
        );

        IMOPNMiningData(governance.miningDataContract())
            .setCollectionAdditionalNFTPoint(
                collectionAddress,
                additionalNFTPoints
            );
    }

    function linkCheck(
        address payable account,
        address payable linkedAccount,
        uint32 tileCoordinate
    ) internal view {
        IMOPNMiningData miningData = IMOPNMiningData(
            governance.miningDataContract()
        );
        (, address accountCollection, ) = IERC6551Account(account).token();
        if (linkedAccount != address(0)) {
            (, address linkedAccountCollection, ) = IERC6551Account(
                linkedAccount
            ).token();
            require(
                accountCollection == linkedAccountCollection,
                "link to enemy"
            );
            require(linkedAccount != account, "link to yourself");
            require(
                tileCoordinate.distance(
                    miningData.getAccountCoordinate(linkedAccount)
                ) < 3,
                "linked avatar too far away"
            );
        } else {
            uint256 collectionOnMapNum = miningData.getCollectionOnMapNum(
                accountCollection
            );
            require(
                collectionOnMapNum == 0 ||
                    (miningData.getAccountCoordinate(account) > 0 &&
                        collectionOnMapNum == 1),
                "linked avatar missing"
            );
        }
    }

    modifier tileCheck(uint32 tileCoordinate) {
        tileCoordinate.check();
        _;
    }

    modifier ownerCheck(NFTParams calldata params) {
        require(ownerOf(params, msg.sender) == msg.sender, "not your nft");
        _;
    }

    modifier onlyMiningData() {
        require(
            msg.sender == governance.miningDataContract() ||
                msg.sender == address(this),
            "not allowed"
        );
        _;
    }
}
