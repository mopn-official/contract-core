// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMap.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
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
contract Avatar is IAvatar, Multicall, Ownable {
    struct AvatarData {
        uint256 tokenId;
        /// @notice uint64 avatar bomb used number + uint 64 avatar nft collection id + uint32 avatar on map coordinate
        uint256 setData;
    }

    using TileMath for uint32;

    event AvatarMint(
        uint256 indexed avatarId,
        uint256 indexed COID,
        address collectionContract,
        uint256 tokenId
    );

    /**
     * @notice This event emit when an avatar jump into the map
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId MOPN Land Id
     * @param tileCoordinate tile coordinate
     */
    event AvatarJumpIn(
        uint256 indexed avatarId,
        uint256 indexed COID,
        uint32 indexed LandId,
        uint32 tileCoordinate
    );

    /**
     * @notice This event emit when an avatar move on map
     * @param avatarId avatar Id
     * @param COID collection Id
     * @param LandId MOPN Land Id
     * @param fromCoordinate tile coordinate
     * @param toCoordinate tile coordinate
     */
    event AvatarMove(
        uint256 indexed avatarId,
        uint256 indexed COID,
        uint32 indexed LandId,
        uint32 fromCoordinate,
        uint32 toCoordinate
    );

    /**
     * @notice BombUse Event emit when a Bomb is used at a coordinate by an avatar
     * @param avatarId avatarId that has indexed
     * @param tileCoordinate the tileCoordinate
     * @param victims thje victims that bombed out of the map
     */
    event BombUse(
        uint256 indexed avatarId,
        uint32 tileCoordinate,
        uint256[] victims,
        uint32[] victimsCoordinates
    );

    /** 
        avatar storage map
        avatarId => AvatarData
    */
    mapping(uint256 => AvatarData) public avatarNoumenon;

    // token map of Collection => tokenId => avatarId
    mapping(address => mapping(uint256 => uint256)) public tokenMap;

    uint256 public currentAvatarId;

    address public governanceContract;

    /**
     * @dev set the governance contract address
     * @dev this function also get the Map contract from the governances
     * @param governanceContract_ Governance Contract Address
     */
    function setGovernanceContract(
        address governanceContract_
    ) public onlyOwner {
        governanceContract = governanceContract_;
    }

    function getNFTAvatarId(
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        return tokenMap[contractAddress][tokenId];
    }

    function getAvatarTokenId(uint256 avatarId) public view returns (uint256) {
        return avatarNoumenon[avatarId].tokenId;
    }

    /**
     * @notice get avatar bomb used number
     * @param avatarId avatar Id
     * @return bomb used number
     */
    function getAvatarBombUsed(uint256 avatarId) public view returns (uint256) {
        return uint64(avatarNoumenon[avatarId].setData >> 96);
    }

    function addAvatarBombUsed(uint256 avatarId) internal {
        avatarNoumenon[avatarId].setData += 1 << 96;
    }

    /**
     * @notice get avatar collection id
     * @param avatarId avatar Id
     * @return COID colletion id
     */
    function getAvatarCOID(uint256 avatarId) public view returns (uint256) {
        return uint64(avatarNoumenon[avatarId].setData >> 32);
    }

    /**
     * @notice get avatar on map coordinate
     * @param avatarId avatar Id
     * @return tileCoordinate tile coordinate
     */
    function getAvatarCoordinate(
        uint256 avatarId
    ) public view returns (uint32) {
        return uint32(avatarNoumenon[avatarId].setData);
    }

    function setAvatarCoordinate(
        uint256 avatarId,
        uint32 tileCoordinate
    ) internal {
        uint256 mask = uint256(uint32(0xFFFFFFFF));
        avatarNoumenon[avatarId].setData =
            (avatarNoumenon[avatarId].setData & ~mask) |
            (uint256(tileCoordinate) & mask);
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
                IGovernance(governanceContract).getCollectionContract(COID),
                avatarNoumenon[avatarId].tokenId,
                delegateWallet,
                vault
            );
    }

    /**
     * @notice mint an avatar for a NFT
     * @param params NFTParams
     */
    function mintAvatar(NFTParams calldata params) internal returns (uint256) {
        uint256 COID = IGovernance(governanceContract).getCollectionCOID(
            params.collectionContract
        );
        if (COID == 0) {
            COID = IGovernance(governanceContract).generateCOID(
                params.collectionContract,
                params.proofs
            );
        } else {
            IGovernance(governanceContract).addCollectionAvatarNum(COID);
        }

        currentAvatarId++;

        avatarNoumenon[currentAvatarId].setData = COID << 32;
        avatarNoumenon[currentAvatarId].tokenId = params.tokenId;

        tokenMap[params.collectionContract][params.tokenId] = currentAvatarId;
        emit AvatarMint(
            currentAvatarId,
            COID,
            params.collectionContract,
            params.tokenId
        );
        return currentAvatarId;
    }

    /**
     * @notice an on map avatar move to a new tile
     * @param params NFTParams
     */
    function moveTo(
        NFTParams calldata params,
        uint32 tileCoordinate,
        uint256 linkedAvatarId,
        uint32 LandId
    )
        public
        tileCheck(tileCoordinate)
        ownerCheck(
            params.collectionContract,
            params.tokenId,
            params.delegateWallet,
            params.vault
        )
    {
        uint256 avatarId = tokenMap[params.collectionContract][params.tokenId];
        if (avatarId == 0) {
            avatarId = mintAvatar(params);
        }
        linkCheck(avatarId, linkedAvatarId, tileCoordinate);

        uint256 COID = getAvatarCOID(avatarId);
        uint32 orgCoordinate = getAvatarCoordinate(avatarId);
        if (orgCoordinate > 0) {
            IMap(IGovernance(governanceContract).mapContract()).avatarRemove(
                orgCoordinate,
                0
            );

            emit AvatarMove(
                avatarId,
                COID,
                LandId,
                orgCoordinate,
                tileCoordinate
            );
        } else {
            IGovernance(governanceContract).addCollectionOnMapNum(COID);
            emit AvatarJumpIn(avatarId, COID, LandId, tileCoordinate);
        }

        IMap(IGovernance(governanceContract).mapContract()).avatarSet(
            avatarId,
            COID,
            tileCoordinate,
            LandId,
            getAvatarBombUsed(avatarId)
        );

        if (orgCoordinate == 0) {
            IGovernance(governanceContract).redeemCollectionInboxMT(
                msg.sender,
                avatarId,
                COID
            );
        }

        setAvatarCoordinate(avatarId, tileCoordinate);
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
        ownerCheck(
            params.collectionContract,
            params.tokenId,
            params.delegateWallet,
            params.vault
        )
    {
        uint256 avatarId = tokenMap[params.collectionContract][params.tokenId];
        if (avatarId == 0) {
            avatarId = mintAvatar(params);
        }
        addAvatarBombUsed(avatarId);

        if (getAvatarCoordinate(avatarId) > 0) {
            IMap(IGovernance(governanceContract).mapContract()).addMTAW(
                avatarId,
                getAvatarCOID(avatarId),
                IMap(IGovernance(governanceContract).mapContract())
                    .getTileLandId(getAvatarCoordinate(avatarId)),
                1
            );
        }

        IGovernance(governanceContract).burnBomb(msg.sender, 1);

        uint256[] memory attackAvatarIds = new uint256[](7);
        uint32[] memory victimsCoordinates = new uint32[](7);
        uint32 orgTileCoordinate = tileCoordinate;

        for (uint256 i = 0; i < 7; i++) {
            uint256 attackAvatarId = IMap(
                IGovernance(governanceContract).mapContract()
            ).avatarRemove(tileCoordinate, avatarId);

            if (attackAvatarId > 0) {
                setAvatarCoordinate(attackAvatarId, 0);
                IGovernance(governanceContract).subCollectionOnMapNum(
                    getAvatarCOID(attackAvatarId)
                );
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

    function linkCheck(
        uint256 avatarId,
        uint256 linkedAvatarId,
        uint32 tileCoordinate
    ) internal view {
        uint256 COID = getAvatarCOID(avatarId);
        require(COID > 0, "avatar not exist");

        if (linkedAvatarId > 0) {
            require(COID == getAvatarCOID(linkedAvatarId), "link to enemy");
            require(linkedAvatarId != avatarId, "link to yourself");
            require(
                tileCoordinate.distance(getAvatarCoordinate(linkedAvatarId)) <
                    3,
                "linked avatar too far away"
            );
        } else {
            uint256 collectionOnMapNum = IGovernance(governanceContract)
                .getCollectionOnMapNum(COID);
            require(
                collectionOnMapNum == 0 ||
                    (getAvatarCoordinate(avatarId) > 0 &&
                        collectionOnMapNum == 1),
                "linked avatar missing"
            );
        }
    }

    modifier tileCheck(uint32 tileCoordinate) {
        tileCoordinate.check();
        _;
    }

    modifier ownerCheck(
        address collectionContract,
        uint256 tokenId,
        DelegateWallet delegateWallet,
        address vault
    ) {
        require(
            ownerOf(collectionContract, tokenId, delegateWallet, vault) ==
                msg.sender,
            "not your nft"
        );
        _;
    }

    modifier onlyMap() {
        require(
            msg.sender == IGovernance(governanceContract).mapContract() ||
                msg.sender == address(this),
            "not allowed"
        );
        _;
    }
}
