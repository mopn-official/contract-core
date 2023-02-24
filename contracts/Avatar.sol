// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMap.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error LandIdTilesNotOpen();
error linkAvatarError();

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
contract Avatar is IAvatar, Multicall, Ownable {
    struct AvatarData {
        uint256 tokenId;
        uint256 setData;
    }

    using Math for uint256;
    using TileMath for uint32;

    /**
     * @notice BombUse Event emit when a Bomb is used at a coordinate by an avatar
     * @param avatarId avatarId that has indexed
     * @param tileCoordinate the tileCoordinate
     */
    event BombUse(uint256 indexed avatarId, uint32 tileCoordinate);

    /** 
        avatar storage map
        avatarId => AvatarData
    */
    mapping(uint256 => AvatarData) public avatarNoumenon;

    // token map of Collection => tokenId => avatarId
    mapping(uint256 => mapping(uint256 => uint256)) public tokenMap;

    uint256 public currentAvatarId;

    IMap private Map;
    IGovernance private Governance;

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
        avatarData.tileCoordinate = getAvatarCoordinate(avatarId);
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
        address[] calldata collections,
        uint256[] calldata tokenIds
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
     * @notice get avatar infos by tile sets start by start coordinate and range by width and height
     * @param startCoordinate start tile coordinate
     * @param width range width
     * @param height range height
     */
    function getAvatarsByCoordinateRange(
        uint32 startCoordinate,
        uint32 width,
        uint32 height
    ) public view returns (AvatarDataOutput[] memory avatarDatas) {
        uint32 coordinate = startCoordinate;
        for (uint256 i = 0; i < height; i++) {
            for (uint256 j = 0; j < width; j++) {
                avatarDatas[coordinate] = getAvatarByAvatarId(
                    Map.getTileAvatar(coordinate)
                );
                coordinate = coordinate.neighbor((j % 2 == 0 ? 5 : 1));
            }
            startCoordinate = startCoordinate.neighbor(1);
            coordinate = startCoordinate;
        }
    }

    /**
     * @notice get avatar infos by tile sets start by start coordinate and end by end coordinates
     * @param startCoordinate start tile coordinate
     * @param endCoordinate end tile coordinate
     */
    function getAvatarsByStartEndCoordinate(
        uint32 startCoordinate,
        uint32 endCoordinate
    ) public view returns (AvatarDataOutput[] memory avatarDatas) {
        TileMath.XYCoordinate memory startxy = startCoordinate.coordinateToXY();
        TileMath.XYCoordinate memory endxy = endCoordinate.coordinateToXY();
        uint32 width = uint32(endxy.x - startxy.x);
        uint32 height = uint32(startxy.y - endxy.y) - (width / 2);
        width += 1;
        return getAvatarsByCoordinateRange(startCoordinate, width, height);
    }

    //@todo get avatars by coordinate array

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
     * @return tileCoordinate tile coordinate
     */
    function getAvatarCoordinate(
        uint256 avatarId
    ) public view returns (uint32) {
        return uint32(avatarNoumenon[avatarId].setData % 10 ** 8);
    }

    address public constant WARM_CONTRACT_ADDRESS =
        0xC3AA9bc72Bd623168860a1e5c6a4530d3D80456c;

    address public constant DelegateCash_CONTRACT_ADDRESS =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    /**
     * @notice get the original owner of a NFT
     * MOPN Avatar support hot wallet protocol https://delegate.cash/ and https://warm.xyz/ to verify your NFTs
     * @param collectionContract NFT collection Contract Address
     * @param tokenId NFT tokenId
     * @param delegateWallet DelegateWallet enum to specify protocol
     * @param vault cold wallet address
     * @return owner nft owner or nft delegate hot wallet
     */
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

    /**
     * @notice get the original owner of a avatar linked nft
     * @param avatarId avatar Id
     * @param delegateWallet DelegateWallet enum to specify protocol
     * @param vault cold wallet address
     * @return owner nft owner or nft delegate hot wallet
     */
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

    /**
     * @notice mint an avatar for a NFT
     * @param collectionContract NFT collection Contract Address
     * @param tokenId NFT tokenId
     * @param proofs NFT collection whitelist proof
     * @param delegateWallet DelegateWallet enum to specify protocol
     * @param vault cold wallet address
     */
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
        uint256 COID = Governance.generateCOID(collectionContract, proofs);
        require(tokenMap[COID][tokenId] == 0, "avatar exist");

        currentAvatarId++;

        avatarNoumenon[currentAvatarId].setData = COID * 10 ** 8;
        avatarNoumenon[currentAvatarId].tokenId = tokenId;

        tokenMap[COID][tokenId] = currentAvatarId;
        return currentAvatarId;
    }

    /**
     * @notice an off map avatar jump in to the map
     * @param params OnMapParams
     */
    function jumpIn(
        OnMapParams calldata params
    )
        public
        tileCheck(params.tileCoordinate)
        ownerCheck(params.avatarId, params.delegateWallet, params.vault)
        linkCheck(params)
    {
        require(getAvatarCoordinate(params.avatarId) == 0, "avatar is on map");

        uint256 COID = getAvatarCOID(params.avatarId);
        uint256 avatarBombUsed = getAvatarBombUsed(params.avatarId);

        Map.avatarSet(
            params.avatarId,
            COID,
            params.tileCoordinate,
            params.LandId,
            avatarBombUsed
        );

        setAvatarCoordinate(params.avatarId, params.tileCoordinate);
        Governance.addCollectionOnMapNum(COID);
        Governance.redeemCollectionInboxEnergy(params.avatarId, COID);
    }

    /**
     * @notice an on map avatar move to a new tile
     * @param params OnMapParams
     */
    function moveTo(
        OnMapParams calldata params
    )
        public
        tileCheck(params.tileCoordinate)
        ownerCheck(params.avatarId, params.delegateWallet, params.vault)
        linkCheck(params)
    {
        uint256 COID = getAvatarCOID(params.avatarId);
        require(getAvatarCoordinate(params.avatarId) != 0, "avatar not on map");
        Map.avatarRemove(
            params.avatarId,
            COID,
            getAvatarCoordinate(params.avatarId)
        );

        Map.avatarSet(
            params.avatarId,
            COID,
            params.tileCoordinate,
            params.LandId,
            0
        );

        setAvatarCoordinate(params.avatarId, params.tileCoordinate);
    }

    /**
     * @notice throw a bomb to a tile
     * @param tileCoordinate bombing tile coordinate
     * @param avatarId bomb using avatar id
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    function bomb(
        uint32 tileCoordinate,
        uint256 avatarId,
        DelegateWallet delegateWallet,
        address vault
    )
        public
        tileCheck(tileCoordinate)
        ownerCheck(avatarId, delegateWallet, vault)
    {
        addAvatarBombUsed(avatarId);
        if (getAvatarCoordinate(avatarId) > 0) {
            Governance.burnBomb(
                msg.sender,
                1,
                avatarId,
                getAvatarCOID(avatarId),
                Map.getTileLandId(getAvatarCoordinate(avatarId))
            );
        } else {
            Governance.burnBomb(msg.sender, 1, 0, 0, 0);
        }

        uint256 attackAvatarId;
        for (uint256 i = 0; i < 7; i++) {
            attackAvatarId = Map.getTileAvatar(tileCoordinate);
            if (i == 0) {
                tileCoordinate = tileCoordinate.neighbor(4);
            } else {
                tileCoordinate = tileCoordinate.neighbor(i - 1);
            }
            if (attackAvatarId == 0 || attackAvatarId == avatarId) {
                continue;
            }
            deFeat(attackAvatarId);
        }
        emit BombUse(avatarId, tileCoordinate);
    }

    function addAvatarBombUsed(uint256 avatarId) internal {
        avatarNoumenon[avatarId].setData += 10 ** 18;
    }

    function setAvatarCoordinate(
        uint256 avatarId,
        uint32 tileCoordinate
    ) internal {
        avatarNoumenon[avatarId].setData =
            avatarNoumenon[avatarId].setData -
            (avatarNoumenon[avatarId].setData % 10 ** 8) +
            uint256(tileCoordinate);
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

    modifier tileCheck(uint32 tileCoordinate) {
        tileCoordinate.check();
        _;
    }

    modifier linkCheck(OnMapParams calldata params) {
        uint256 COID = getAvatarCOID(params.avatarId);
        require(COID > 0, "avatar not exist");

        if (params.linkedAvatarId > 0) {
            require(
                COID == getAvatarCOID(params.linkedAvatarId),
                "link co error"
            );
            require(
                params.linkedAvatarId != params.avatarId,
                "link to yourself"
            );
            if (
                params.tileCoordinate.distance(
                    getAvatarCoordinate(params.linkedAvatarId)
                ) > 3
            ) {
                revert linkAvatarError();
            }
        } else {
            uint256 collectionOnMapNum = Governance.getCollectionOnMapNum(COID);
            if (collectionOnMapNum > 0) {
                if (
                    !(getAvatarCoordinate(params.avatarId) > 0 &&
                        collectionOnMapNum == 1)
                ) {
                    revert linkAvatarError();
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
