// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./erc6551/interfaces/IERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNData.sol";
import "./interfaces/IMOPNLand.sol";
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

    // Tile => uint160 account + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

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

    function createNFTAccount(
        NFTParams calldata params
    ) public returns (address account) {
        account = IERC6551Registry(governance.erc6551Registry()).createAccount(
            governance.erc6551AccountImplementation(),
            governance.chainId(),
            params.collectionAddress,
            params.tokenId,
            1,
            "0x"
        );
        emit NFTJoin(account, params.collectionAddress, params.tokenId);
    }

    /**
     * @notice an on map avatar move to a new tile
     * @param params NFTParams
     */
    function moveTo(
        NFTParams calldata params,
        uint32 tileCoordinate,
        uint32 LandId
    ) public {
        tileCoordinate.check();
        address account = getNFTAccount(params);
        require(account == msg.sender, "not allowed");

        require(getTileAccount(tileCoordinate) == address(0), "dst Occupied");

        if (LandId == 0 || getTileLandId(tileCoordinate) != LandId) {
            require(
                LandId < IMOPNLand(governance.landContract()).MAX_SUPPLY(),
                "landId overflow"
            );
            require(
                tileCoordinate.distance(LandId.LandCenterTile()) < 6,
                "LandId error"
            );
            require(
                IMOPNLand(governance.landContract()).nextTokenId() > LandId,
                "Land Not Open"
            );
        }

        IMOPNData mopnData = IMOPNData(governance.miningDataContract());
        if (mopnData.getAccountPerNFTPointMinted(account) == 0) {
            emit NFTJoin(account, params.collectionAddress, params.tokenId);
        }

        uint32 orgCoordinate = mopnData.getAccountCoordinate(account);
        uint256 orgNFTPoint;
        if (orgCoordinate > 0) {
            accountRemove(orgCoordinate);
            orgNFTPoint = orgCoordinate.getTileNFTPoint();

            emit NFTMove(account, LandId, orgCoordinate, tileCoordinate);
        } else {
            emit NFTJumpIn(account, LandId, tileCoordinate);
        }

        uint256 tileNFTPoint = tileCoordinate.getTileNFTPoint();
        accountSet(account, tileCoordinate, LandId);

        mopnData.setAccountCoordinate(account, tileCoordinate);
        if (tileNFTPoint > orgNFTPoint) {
            mopnData.addNFTPoint(account, tileNFTPoint - orgNFTPoint);
        } else if (orgNFTPoint < tileNFTPoint) {
            mopnData.subNFTPoint(account, orgNFTPoint - tileNFTPoint);
        }
    }

    /**
     * @notice throw a bomb to a tile
     * @param params NFTParams
     */
    function bomb(NFTParams calldata params, uint32 tileCoordinate) public {
        tileCoordinate.check();
        address account = getNFTAccount(params);
        require(account == msg.sender, "not allowed");

        IMOPNData mopnData = IMOPNData(governance.miningDataContract());
        if (mopnData.getAccountPerNFTPointMinted(account) == 0) {
            emit NFTJoin(account, params.collectionAddress, params.tokenId);
        }

        governance.burnBomb(msg.sender, 1);

        address[] memory attackAccounts = new address[](7);
        uint32[] memory victimsCoordinates = new uint32[](7);
        uint32 orgTileCoordinate = tileCoordinate;

        for (uint256 i = 0; i < 7; i++) {
            address attackAccount = getTileAccount(tileCoordinate);
            if (attackAccount != address(0) && attackAccount != account) {
                accountRemove(tileCoordinate);
                mopnData.setAccountCoordinate(attackAccount, 0);
                attackAccounts[i] = attackAccount;
                victimsCoordinates[i] = tileCoordinate;
                mopnData.subNFTPoint(attackAccount, 0);
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

        IMOPNData(governance.miningDataContract())
            .setCollectionAdditionalNFTPoint(
                collectionAddress,
                additionalNFTPoints
            );
    }

    /**
     * @notice get the avatar Id who is standing on a tile
     * @param tileCoordinate tile coordinate
     */
    function getTileAccount(
        uint32 tileCoordinate
    ) public view returns (address) {
        return address(uint160(tiles[tileCoordinate] >> 32));
    }

    /**
     * @notice get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)
     * @param tileCoordinate tile coordinate
     */
    function getTileLandId(uint32 tileCoordinate) public view returns (uint32) {
        return uint32(tiles[tileCoordinate]);
    }

    /**
     * @notice get the coid of the avatar who is standing on a tile
     * @param account account wallet
     */
    function getAccountCollection(
        address account
    ) public view returns (address collectionAddress) {
        (, collectionAddress, ) = IERC6551Account(payable(account)).token();
    }

    /**
     * @notice avatar id occupied a tile
     * @param account avatar Id
     * @param tileCoordinate tile coordinate
     * @param LandId MOPN Land Id
     * @dev can only called by avatar contract
     */
    function accountSet(
        address account,
        uint32 tileCoordinate,
        uint32 LandId
    ) internal returns (bool collectionLinked) {
        tiles[tileCoordinate] =
            (uint256(uint160(account)) << 32) |
            uint256(LandId);
        tileCoordinate = tileCoordinate.neighbor(4);

        address collectionAddress = getAccountCollection(account);

        address tileAccount;
        address tileCollectionAddress;
        for (uint256 i = 0; i < 18; i++) {
            tileAccount = getTileAccount(tileCoordinate);
            if (tileAccount != address(0) && tileAccount != account) {
                tileCollectionAddress = getAccountCollection(tileAccount);
                require(
                    tileCollectionAddress == collectionAddress,
                    "tile has enemy"
                );
                collectionLinked = true;
            }

            if (i == 5) {
                tileCoordinate = tileCoordinate.neighbor(4).neighbor(5);
            } else if (i < 5) {
                tileCoordinate = tileCoordinate.neighbor(i);
            } else {
                tileCoordinate = tileCoordinate.neighbor((i - 6) / 2);
            }
        }

        if (collectionLinked == false) {
            IMOPNData mopnData = IMOPNData(governance.miningDataContract());
            uint256 collectionOnMapNum = mopnData.getCollectionOnMapNum(
                collectionAddress
            );
            require(
                collectionOnMapNum == 0 ||
                    (mopnData.getAccountCoordinate(account) > 0 &&
                        collectionOnMapNum == 1),
                "linked avatar missing"
            );
        }
    }

    /**
     * @notice avatar id left a tile
     * @param tileCoordinate tile coordinate
     * @dev can only called by avatar contract
     */
    function accountRemove(uint32 tileCoordinate) internal {
        uint32 LandId = getTileLandId(tileCoordinate);
        tiles[tileCoordinate] = LandId;
    }
}
