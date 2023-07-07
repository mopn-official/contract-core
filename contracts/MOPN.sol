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

/// @title MOPN Avatar Contract
/// @author Cyanface <cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract MOPN is IMOPN, Multicall, Ownable {
    using TileMath for uint32;

    event NFTJoin(
        address indexed account,
        address collectionAddress,
        uint256 tokenId
    );

    /**
     * @notice This event emit when an avatar jump into the map
     * @param account account wallet address
     * @param collectionAddress collection contract address
     * @param LandId MOPN Land Id
     * @param tileCoordinate tile coordinate
     */
    event NFTJumpIn(
        address indexed account,
        address indexed collectionAddress,
        uint32 indexed LandId,
        uint32 tileCoordinate
    );

    /**
     * @notice This event emit when an avatar move on map
     * @param account account wallet address
     * @param collectionAddress collection contract address
     * @param LandId MOPN Land Id
     * @param fromCoordinate tile coordinate
     * @param toCoordinate tile coordinate
     */
    event NFTMove(
        address indexed account,
        address indexed collectionAddress,
        uint32 indexed LandId,
        uint32 fromCoordinate,
        uint32 toCoordinate
    );

    /**
     * @notice BombUse Event emit when a Bomb is used at a coordinate by an avatar
     * @param account account wallet address
     * @param tileCoordinate the tileCoordinate
     * @param victims the victims that bombed out of the map
     */
    event BombUse(
        address indexed account,
        uint32 tileCoordinate,
        uint256[] victims,
        uint32[] victimsCoordinates
    );

    IMOPNGovernance public governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function getNFTAccount(
        NFTParams calldata params
    ) public view returns (address) {
        return
            IERC6551Registry(governance.erc6551Registry()).account(
                governance.erc6551AccountImplementation(),
                governance.chainId(),
                params.collectionAddress,
                params.tokenId,
                1
            );
    }

    function getNFTAccountOwner(
        NFTParams calldata params
    ) public view returns (address) {
        address account = getNFTAccount(params);
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
        address account = getNFTAccount(params);
        if (account == operator) {
            return operator;
        }
        address accountowner = IERC6551Account(account).ownerOf();
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
        address linkedAccount,
        uint32 LandId
    )
        public
        tileCheck(tileCoordinate)
        ownerCheck(params.collectionContract, params.tokenId)
    {
        address account = getNFTAccount(params);
        IMOPNMiningData memory miningData = IMOPNMiningData(
            governance.miningDataContract()
        );
        if (miningData.getAccountPerNFTPointMinted(account) == 0) {
            emit NFTJoin(account, params.collectionAddress, params.tokenId);
        }
        linkCheck(account, linkedAccount, tileCoordinate);

        uint32 orgCoordinate = miningData.getAccountCoordinate(account);
        if (orgCoordinate > 0) {
            IMOPNMap(governance.mapContract()).avatarRemove(orgCoordinate, 0);

            emit NFTMove(
                account,
                params.contractAddress,
                LandId,
                orgCoordinate,
                tileCoordinate
            );
        } else {
            miningData.addCollectionOnMapNum(params.collectionAddress);
            emit NFTJumpIn(
                account,
                params.contractAddress,
                LandId,
                tileCoordinate
            );
        }

        IMOPNMap(governance.mapContract()).avatarSet(
            avatarId,
            COID,
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
    )
        public
        tileCheck(tileCoordinate)
        ownerCheck(params.collectionContract, params.tokenId)
    {
        uint256 avatarId = tokenMap[params.collectionContract][params.tokenId];
        if (avatarId == 0) {
            avatarId = mintAvatar(params);
        }
        addAvatarBombUsed(avatarId);

        if (getAvatarCoordinate(avatarId) > 0) {
            IMOPNMiningData(governance.miningDataContract()).addNFTPoint(
                avatarId,
                getAvatarCOID(avatarId),
                1
            );
        }

        governance.burnBomb(msg.sender, 1);

        uint256[] memory attackAvatarIds = new uint256[](7);
        uint32[] memory victimsCoordinates = new uint32[](7);
        uint32 orgTileCoordinate = tileCoordinate;

        for (uint256 i = 0; i < 7; i++) {
            uint256 attackAvatarId = IMOPNMap(governance.mapContract())
                .avatarRemove(tileCoordinate, avatarId);

            if (attackAvatarId > 0) {
                setAvatarCoordinate(attackAvatarId, 0);
                subCollectionOnMapNum(getAvatarCOID(attackAvatarId));
                attackAvatarIds[i] = attackAvatarId;
                victimsCoordinates[i] = tileCoordinate;
            }

            if (i == 0) {
                tileCoordinate = tileCoordinate.neighbor(4);
            } else {
                tileCoordinate = tileCoordinate.neighbor(i - 1);
            }
        }

        emit BombUse(
            avatarId,
            orgTileCoordinate,
            attackAvatarIds,
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
        address account,
        address linkedAccount,
        uint32 tileCoordinate
    ) internal view {
        IMOPNMiningData memory miningData = IMOPNMiningData(
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

    modifier ownerCheck(address collectionContract, uint256 tokenId) {
        require(
            ownerOf(collectionContract, tokenId) == msg.sender,
            "not your nft"
        );
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
