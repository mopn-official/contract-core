// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "./libraries/BlockMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface WarmInterface {
    function ownerOf(
        address contractAddress,
        uint256 tokenId
    ) external view returns (address);
}

interface DelegateCashInterface {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

/// @title MOPN Avatar Contract
/// @author Cyanface <cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract Avatar is Multicall, Ownable {
    struct AvatarData {
        uint256 tokenId;
        uint256 setData;
    }

    struct AvatarDataOutput {
        uint256 tokenId;
        uint256 COID;
        uint256 BombUsed;
        uint32 blockCoordinate;
    }

    using Math for uint256;
    using BlockMath for uint32;

    /**
     * @notice BombUse Event emit when a Bomb is used at a coordinate by an avatar
     * @param avatarId avatarId that has indexed
     * @param blockCoordinate the blockCoordinate
     */
    event BombUse(uint256 indexed avatarId, uint32 blockCoordinate);

    /** 
        avatar storage map
        avatarId => AvatarData
    */
    mapping(uint256 => AvatarData) public avatarNoumenon;

    // token map of Collection => tokenId => avatarId
    mapping(uint256 => mapping(uint256 => uint256)) public tokenMap;

    uint256 public currentAvatarId;

    IMap public Map;
    IGovernance public Governance;

    /**
     * @dev set the governance contract address
     * @dev this function also get the Map contract from the governances
     * @param governanceContract_ Governance Contract Address
     */
    function setGovernanceContract(address governanceContract_) public {
        Governance = IGovernance(governanceContract_);
        Map = IMap(Governance.mapContract());
    }

    /**
     * @notice get avatar info by avatarId
     * @param avatarId avatar Id
     * @return avatarData avatar data format struct AvatarDataOutput
     */
    function getAvatarByAvatarId(
        uint256 avatarId
    ) public view returns (AvatarDataOutput memory avatarData) {
        avatarData.tokenId = avatarNoumenon[avatarId].tokenId;
        avatarData.COID = getAvatarCOID(avatarId);
        avatarData.BombUsed = getAvatarBombUsed(avatarId);
        avatarData.blockCoordinate = getAvatarCoordinate(avatarId);
    }

    /**
     * @notice get avatar info by nft contractAddress and tokenId
     * @param collection  collection contract address
     * @param tokenId  token Id
     * @return avatarData avatar data format struct AvatarDataOutput
     */
    function getAvatarByNFT(
        address collection,
        uint256 tokenId
    ) public view returns (AvatarDataOutput memory avatarData) {
        uint256 avatarId = tokenMap[Governance.getCollectionCOID(collection)][
            tokenId
        ];
        avatarData = getAvatarByAvatarId(avatarId);
    }

    /**
     * @notice get avatar infos by nft contractAddresses and tokenIds
     * @param collections array of collection contract address
     * @param tokenIds array of token Ids
     * @return avatarDatas avatar datas format struct AvatarDataOutput
     */
    function getAvatarsByNFTs(
        address[] memory collections,
        uint256[] memory tokenIds
    ) public view returns (AvatarDataOutput[] memory avatarDatas) {
        uint256[] memory COIDs = Governance.getCollectionsCOIDs(collections);
        avatarDatas = new AvatarDataOutput[](COIDs.length);
        for (uint256 i = 0; i < COIDs.length; i++) {
            avatarDatas[i] = getAvatarByAvatarId(
                tokenMap[COIDs[i]][tokenIds[i]]
            );
        }
    }

    /**
     * @notice get avatar collection id
     * @param avatarId avatar Id
     * @return COID colletion id
     */
    function getAvatarCOID(uint256 avatarId) public view returns (uint256) {
        return (avatarNoumenon[avatarId].setData % 10 ** 18) / 10 ** 8;
    }

    /**
     * @notice get avatar bomb used number
     * @param avatarId avatar Id
     * @return bomb used number
     */
    function getAvatarBombUsed(uint256 avatarId) public view returns (uint256) {
        return avatarNoumenon[avatarId].setData / 10 ** 18;
    }

    /**
     * @notice get avatar on map coordinate
     * @param avatarId avatar Id
     * @return blockCoordinate block coordinate
     */
    function getAvatarCoordinate(
        uint256 avatarId
    ) public view returns (uint32) {
        return uint32(avatarNoumenon[avatarId].setData % 10 ** 8);
    }

    enum DelegateWallet {
        None,
        DelegateCash,
        Warm
    }

    address public constant WARM_CONTRACT_ADDRESS =
        0xC3AA9bc72Bd623168860a1e5c6a4530d3D80456c;

    address public constant DelegateCash_CONTRACT_ADDRESS =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    function ownerOf(
        uint256 avatarId,
        DelegateWallet delegateWallet,
        address vault
    ) public view returns (address) {
        uint256 COID = getAvatarCOID(avatarId);
        require(COID > 0, "avatar not exist");
        return
            ownerOf(
                Governance.getCollectionContract(COID),
                avatarNoumenon[avatarId].tokenId,
                delegateWallet,
                vault
            );
    }

    function ownerOf(
        address collectionContract,
        uint256 tokenId,
        DelegateWallet delegateWallet,
        address vault
    ) public view returns (address owner) {
        if (delegateWallet == DelegateWallet.None) {
            return IERC721(collectionContract).ownerOf(tokenId);
        } else if (delegateWallet == DelegateWallet.DelegateCash) {
            if (
                DelegateCashInterface(DelegateCash_CONTRACT_ADDRESS)
                    .checkDelegateForToken(
                        msg.sender,
                        vault,
                        collectionContract,
                        tokenId
                    )
            ) {
                return vault;
            } else {
                return IERC721(collectionContract).ownerOf(tokenId);
            }
        } else if (delegateWallet == DelegateWallet.Warm) {
            return
                WarmInterface(WARM_CONTRACT_ADDRESS).ownerOf(
                    collectionContract,
                    tokenId
                );
        }
    }

    function mintAvatar(
        address collectionContract,
        uint256 tokenId,
        bytes32[] memory proofs,
        DelegateWallet delegateWallet,
        address vault
    ) public returns (uint256) {
        require(
            msg.sender ==
                ownerOf(collectionContract, tokenId, delegateWallet, vault),
            "caller is not token owner"
        );
        uint256 COID = Governance.checkWhitelistCOID(
            collectionContract,
            proofs
        );
        require(tokenMap[COID][tokenId] == 0, "avatar exist");

        currentAvatarId++;

        avatarNoumenon[currentAvatarId].setData = COID * 10 ** 8;
        avatarNoumenon[currentAvatarId].tokenId = tokenId;

        tokenMap[COID][tokenId] = currentAvatarId;
        return currentAvatarId;
    }

    function jumpIn(
        uint32 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId,
        uint32 PassId,
        DelegateWallet delegateWallet,
        address vault
    )
        public
        blockCheck(blockCoordinate)
        ownerCheck(avatarId, delegateWallet, vault)
        linkCheck(blockCoordinate, linkedAvatarId, avatarId)
    {
        require(getAvatarCoordinate(avatarId) == 0, "avatar is on map");

        uint256 COID = getAvatarCOID(avatarId);

        Map.avatarSet(
            avatarId,
            COID,
            blockCoordinate,
            PassId,
            getAvatarBombUsed(avatarId)
        );

        setAvatarCoordinate(avatarId, blockCoordinate);
        Governance.addCollectionOnMapNum(COID);
        Governance.redeemCollectionInboxEnergy(avatarId, COID);
    }

    function moveTo(
        uint32 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId,
        uint32 PassId,
        DelegateWallet delegateWallet,
        address vault
    )
        public
        blockCheck(blockCoordinate)
        ownerCheck(avatarId, delegateWallet, vault)
        linkCheck(blockCoordinate, linkedAvatarId, avatarId)
    {
        uint256 COID = getAvatarCOID(avatarId);
        require(getAvatarCoordinate(avatarId) != 0, "avatar not on map");
        Map.avatarRemove(avatarId, COID, getAvatarCoordinate(avatarId));

        Map.avatarSet(avatarId, COID, blockCoordinate, PassId, 0);

        setAvatarCoordinate(avatarId, blockCoordinate);
    }

    function bomb(
        uint32 blockCoordinate,
        uint256 avatarId,
        DelegateWallet delegateWallet,
        address vault
    )
        public
        blockCheck(blockCoordinate)
        ownerCheck(avatarId, delegateWallet, vault)
    {
        addAvatarBombUsed(avatarId);
        if (getAvatarCoordinate(avatarId) > 0) {
            Governance.burnBomb(
                msg.sender,
                1,
                avatarId,
                getAvatarCOID(avatarId),
                Map.getBlockPassId(getAvatarCoordinate(avatarId))
            );
        } else {
            Governance.burnBomb(msg.sender, 1, 0, 0, 0);
        }

        uint256 attackAvatarId;
        for (uint256 i = 0; i < 7; i++) {
            attackAvatarId = Map.getBlockAvatar(blockCoordinate);
            if (i == 0) {
                blockCoordinate = blockCoordinate.neighbor(4);
            } else {
                blockCoordinate = blockCoordinate.neighbor(i - 1);
            }
            if (attackAvatarId == 0 || attackAvatarId == avatarId) {
                continue;
            }
            deFeat(attackAvatarId);
        }
        emit BombUse(avatarId, blockCoordinate);
    }

    function addAvatarBombUsed(uint256 avatarId) internal {
        avatarNoumenon[avatarId].setData += 10 ** 18;
    }

    function setAvatarCoordinate(
        uint256 avatarId,
        uint32 blockCoordinate
    ) internal {
        avatarNoumenon[avatarId].setData =
            avatarNoumenon[avatarId].setData -
            (avatarNoumenon[avatarId].setData % 10 ** 8) +
            uint256(blockCoordinate);
    }

    function deFeat(uint256 avatarId) internal {
        Map.avatarRemove(
            avatarId,
            getAvatarCOID(avatarId),
            getAvatarCoordinate(avatarId)
        );
        setAvatarCoordinate(avatarId, 0);
        Governance.subCollectionOnMapNum(getAvatarCOID(avatarId));
    }

    modifier ownerCheck(
        uint256 avatarId,
        DelegateWallet delegateWallet,
        address vault
    ) {
        require(
            ownerOf(avatarId, delegateWallet, vault) == msg.sender,
            "not your avatar"
        );
        _;
    }

    modifier blockCheck(uint32 blockCoordinate) {
        blockCoordinate.check();
        _;
    }

    modifier linkCheck(
        uint32 blockCoordinate,
        uint256 linkedAvatarId,
        uint256 avatarId
    ) {
        uint256 COID = getAvatarCOID(avatarId);
        require(COID > 0, "avatar not exist");

        if (linkedAvatarId > 0) {
            require(COID == getAvatarCOID(linkedAvatarId), "link co error");
            require(linkedAvatarId != avatarId, "link to yourself");
            if (
                blockCoordinate.distance(getAvatarCoordinate(linkedAvatarId)) >
                3
            ) {
                revert linkBlockError();
            }
        } else {
            uint256 collectionOnMapNum = Governance.getCollectionOnMapNum(COID);
            if (collectionOnMapNum > 0) {
                if (
                    !(getAvatarCoordinate(avatarId) > 0 &&
                        collectionOnMapNum == 1)
                ) {
                    revert linkBlockError();
                }
            }
        }
        _;
    }

    modifier onlyMap() {
        require(
            msg.sender == address(Map) || msg.sender == address(this),
            "not allowed"
        );
        _;
    }
}
