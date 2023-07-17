// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./erc6551/interfaces/IERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNData.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IMOPNCollectionVault.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

    struct NFTParams {
        address collectionAddress;
        uint256 tokenId;
    }

    struct AccountDataOutput {
        address account;
        address contractAddress;
        uint256 tokenId;
        uint256 BombBadge;
        uint256 MTBalance;
        uint256 MOPNPoint;
        uint32 tileCoordinate;
    }

    struct CollectionDataOutput {
        address contractAddress;
        address collectionVault;
        uint256 OnMapNum;
        uint256 MTBalance;
        uint256 AdditionalMOPNPoints;
        uint256 CollectionMOPNPoints;
        uint256 AvatarMOPNPoints;
        uint256 CollectionMOPNPoint;
        uint256 AdditionalMOPNPoint;
        IMOPNCollectionVault.NFTAuction NFTAuction;
    }

    // Tile => uint160 account + uint32 MOPN Land Id
    mapping(uint32 => uint256) public tiles;

    IMOPNGovernance public governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function getAccountNFT(
        address account
    ) public view returns (address, uint256) {
        require(
            IERC165(payable(account)).supportsInterface(
                type(IERC6551Account).interfaceId
            ),
            "not erc6551 account"
        );

        (
            uint256 chainId,
            address collectionAddress,
            uint256 tokenId
        ) = IERC6551Account(payable(account)).token();

        require(
            chainId == governance.chainId(),
            "not support cross chain account"
        );

        require(
            account ==
                IERC6551Registry(governance.ERC6551Registry()).account(
                    governance.ERC6551AccountProxy(),
                    governance.chainId(),
                    collectionAddress,
                    tokenId,
                    0
                ),
            "not a mopn Account Implementation"
        );

        return (collectionAddress, tokenId);
    }

    /**
     * @notice an on map avatar move to a new tile
     * @param tileCoordinate NFT move To coordinate
     */
    function moveTo(uint32 tileCoordinate, uint32 LandId) public {
        tileCoordinate.check();
        (address collectionAddress, uint256 tokenId) = getAccountNFT(
            msg.sender
        );

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

        IMOPNData mopnData = IMOPNData(governance.mopnDataContract());
        if (mopnData.getAccountPerMOPNPointMinted(msg.sender) == 0) {
            emit AccountJoin(msg.sender, collectionAddress, tokenId);
        }

        uint32 orgCoordinate = mopnData.getAccountCoordinate(msg.sender);
        uint256 orgMOPNPoint;
        if (orgCoordinate > 0) {
            accountRemove(orgCoordinate);
            orgMOPNPoint = orgCoordinate.getTileMOPNPoint();

            emit AccountMove(msg.sender, LandId, orgCoordinate, tileCoordinate);
        } else {
            emit AccountJumpIn(msg.sender, LandId, tileCoordinate);
        }

        uint256 tileMOPNPoint = tileCoordinate.getTileMOPNPoint();
        accountSet(msg.sender, tileCoordinate, LandId);

        mopnData.setAccountCoordinate(msg.sender, tileCoordinate);

        if (tileMOPNPoint > orgMOPNPoint) {
            mopnData.addMOPNPoint(msg.sender, tileMOPNPoint - orgMOPNPoint);
        } else if (orgMOPNPoint < tileMOPNPoint) {
            mopnData.subMOPNPoint(msg.sender, orgMOPNPoint - tileMOPNPoint);
        }
    }

    /**
     * @notice throw a bomb to a tile
     * @param tileCoordinate bomb to tile coordinate
     */
    function bomb(uint32 tileCoordinate) public {
        tileCoordinate.check();
        getAccountNFT(msg.sender);

        IMOPNData mopnData = IMOPNData(governance.mopnDataContract());
        require(
            mopnData.getAccountCoordinate(msg.sender) > 0,
            "NFT not on the map"
        );

        governance.burnBomb(msg.sender, 1);

        address[] memory attackAccounts = new address[](7);
        uint32[] memory victimsCoordinates = new uint32[](7);
        uint32 orgTileCoordinate = tileCoordinate;

        for (uint256 i = 0; i < 7; i++) {
            address attackAccount = getTileAccount(tileCoordinate);
            if (attackAccount != address(0) && attackAccount != msg.sender) {
                accountRemove(tileCoordinate);
                mopnData.setAccountCoordinate(attackAccount, 0);
                attackAccounts[i] = attackAccount;
                victimsCoordinates[i] = tileCoordinate;
                mopnData.subMOPNPoint(attackAccount, 0);
            }

            if (i == 0) {
                tileCoordinate = tileCoordinate.neighbor(4);
            } else {
                tileCoordinate = tileCoordinate.neighbor(i - 1);
            }
        }

        emit BombUse(
            msg.sender,
            orgTileCoordinate,
            attackAccounts,
            victimsCoordinates
        );
    }

    /**
     * @notice check if this collection is in white list
     * @param collectionAddress collection contract address
     * @param additionalMOPNPoints additional NFT Points
     * @param proofs collection whitelist proofs
     */
    function setCollectionAdditionalMOPNPoints(
        address collectionAddress,
        uint256 additionalMOPNPoints,
        bytes32[] memory proofs
    ) public {
        require(
            MerkleProof.verify(
                proofs,
                governance.whiteListRoot(),
                keccak256(
                    bytes.concat(
                        keccak256(
                            abi.encode(collectionAddress, additionalMOPNPoints)
                        )
                    )
                )
            ),
            "collection additionalMOPNPoints can't verify"
        );

        IMOPNData(governance.mopnDataContract())
            .setCollectionAdditionalMOPNPoint(
                collectionAddress,
                additionalMOPNPoints
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
            IMOPNData mopnData = IMOPNData(governance.mopnDataContract());
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

    function batchMintAccountMT(address[] memory accounts) public {
        IMOPNData miningData = IMOPNData(governance.mopnDataContract());
        miningData.settlePerMOPNPointMinted();
        for (uint256 i = 0; i < accounts.length; i++) {
            address accountCollection = getAccountCollection(accounts[i]);
            miningData.mintCollectionMT(accountCollection);
            miningData.mintAccountMT(accounts[i]);
        }
    }

    function redeemRealtimeLandHolderMT(
        uint32 LandId,
        address[] memory accounts
    ) public {
        batchMintAccountMT(accounts);
        IMOPNData(governance.mopnDataContract()).redeemLandHolderMT(LandId);
    }

    /**
     * @notice batch redeem land holder unclaimed minted mopn token
     * @param LandIds Land Ids
     */
    function batchRedeemRealtimeLandHolderMT(
        uint32[] memory LandIds,
        address[][] memory accounts
    ) public {
        for (uint256 i = 0; i < LandIds.length; i++) {
            batchMintAccountMT(accounts[i]);
        }
        IMOPNData(governance.mopnDataContract()).batchRedeemSameLandHolderMT(
            LandIds
        );
    }

    function getAccountData(
        address account
    ) public view returns (AccountDataOutput memory accountData) {
        IMOPNData miningData = IMOPNData(governance.mopnDataContract());
        accountData.account = account;
        (, address collectionAddress, uint256 tokenId) = IERC6551Account(
            payable(account)
        ).token();

        accountData.tokenId = tokenId;
        accountData.contractAddress = collectionAddress;
        accountData.BombBadge = IMOPNBomb(governance.bombContract()).balanceOf(
            account,
            2
        );
        accountData.MTBalance = IMOPNToken(governance.mtContract()).balanceOf(
            account
        );
        accountData.MOPNPoint = IERC20(governance.pointContract()).balanceOf(
            account
        );
        accountData.tileCoordinate = miningData.getAccountCoordinate(account);
    }

    function getAccountsData(
        address[] memory accounts
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            accountDatas[i] = getAccountData(accounts[i]);
        }
    }

    function getAccountByNFT(
        NFTParams calldata params
    ) public view returns (address) {
        return
            IERC6551Registry(governance.ERC6551Registry()).account(
                governance.ERC6551AccountProxy(),
                governance.chainId(),
                params.collectionAddress,
                params.tokenId,
                0
            );
    }

    /**
     * @notice get avatar info by nft contractAddress and tokenId
     * @param params  collection contract address and tokenId
     * @return accountData avatar data format struct AvatarDataOutput
     */
    function getAccountDataByNFT(
        NFTParams calldata params
    ) public view returns (AccountDataOutput memory accountData) {
        accountData = getAccountData(getAccountByNFT(params));
    }

    /**
     * @notice get avatar infos by nft contractAddresses and tokenIds
     * @param params array of collection contract address and token ids
     * @return accountDatas avatar datas format struct AvatarDataOutput
     */
    function getAccountsDataByNFTs(
        NFTParams[] calldata params
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            accountDatas[i] = getAccountData(getAccountByNFT(params[i]));
        }
    }

    /**
     * @notice get avatars by coordinate array
     * @param coordinates array of coordinates
     * @return accountDatas avatar datas format struct AccountDataOutput
     */
    function getAccountsDataByCoordinates(
        uint32[] memory coordinates
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](coordinates.length);
        for (uint256 i = 0; i < coordinates.length; i++) {
            accountDatas[i] = getAccountData(
                IMOPN(governance.mopnContract()).getTileAccount(coordinates[i])
            );
            accountDatas[i].tileCoordinate = coordinates[i];
        }
    }

    function getBatchAccountMTBalance(
        address[] memory accounts
    ) public view returns (uint256[] memory MTBalances) {
        MTBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            MTBalances[i] = IMOPNToken(governance.mtContract()).balanceOf(
                accounts[i]
            );
        }
    }

    /**
     * get collection contract, on map num, avatar num etc from IGovernance.
     */
    function getCollectionData(
        address collectionAddress
    ) public view returns (CollectionDataOutput memory cData) {
        IMOPNData miningData = IMOPNData(governance.mopnDataContract());
        cData.contractAddress = collectionAddress;
        cData.collectionVault = governance.getCollectionVault(
            collectionAddress
        );

        cData.OnMapNum = miningData.getCollectionOnMapNum(collectionAddress);
        cData.MTBalance = IMOPNToken(governance.mtContract()).balanceOf(
            governance.getCollectionVault(collectionAddress)
        );

        cData.AdditionalMOPNPoints = miningData
            .getCollectionAdditionalMOPNPoints(collectionAddress);

        cData.CollectionMOPNPoints = miningData.getCollectionMOPNPoints(
            collectionAddress
        );
        cData.AvatarMOPNPoints = miningData.getCollectionAccountMOPNPoints(
            collectionAddress
        );
        cData.CollectionMOPNPoint = miningData.getCollectionMOPNPoint(
            collectionAddress
        );
        cData.AdditionalMOPNPoint = miningData.getCollectionAdditionalMOPNPoint(
            collectionAddress
        );

        if (cData.collectionVault != address(0)) {
            cData.NFTAuction = IMOPNCollectionVault(cData.collectionVault)
                .getAuctionInfo();
        }
    }

    function getCollectionsData(
        address[] memory collectionAddresses
    ) public view returns (CollectionDataOutput[] memory cDatas) {
        cDatas = new CollectionDataOutput[](collectionAddresses.length);
        for (uint256 i = 0; i < collectionAddresses.length; i++) {
            cDatas[i] = getCollectionData(collectionAddresses[i]);
        }
    }
}
