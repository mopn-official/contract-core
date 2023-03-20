// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMap.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
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
        /// @notice avatar bomb used number * 10 ** 18 + avatar nft collection id * 10 ** 10 + avatar on map coordinate
        uint256 setData;
    }

    using Math for uint256;
    using TileMath for uint32;

    event AvatarMint(uint256 indexed avatarId, uint256 indexed COID);

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

    /**
     * @notice get avatar collection id
     * @param avatarId avatar Id
     * @return COID colletion id
     */
    function getAvatarCOID(uint256 avatarId) public view returns (uint256) {
        return (avatarNoumenon[avatarId].setData % 10 ** 18) / 10 ** 8;
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
                IGovernance(governanceContract).getCollectionContract(COID),
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
    ) public {
        require(
            msg.sender ==
                ownerOf(collectionContract, tokenId, delegateWallet, vault),
            "caller is not token owner"
        );
        uint256 COID = IGovernance(governanceContract).generateCOID(
            collectionContract,
            proofs
        );
        require(tokenMap[collectionContract][tokenId] == 0, "avatar exist");

        currentAvatarId++;

        avatarNoumenon[currentAvatarId].setData = COID * 10 ** 8;
        avatarNoumenon[currentAvatarId].tokenId = tokenId;

        tokenMap[collectionContract][tokenId] = currentAvatarId;
        emit AvatarMint(currentAvatarId, COID);
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
        ownerCheck(
            params.collectionContract,
            params.tokenId,
            params.delegateWallet,
            params.vault
        )
    {
        uint256 avatarId = tokenMap[params.collectionContract][params.tokenId];
        linkCheck(avatarId, params.linkedAvatarId, params.tileCoordinate);
        require(getAvatarCoordinate(avatarId) == 0, "avatar is on map");

        uint256 COID = getAvatarCOID(avatarId);

        IMap(IGovernance(governanceContract).mapContract()).avatarSet(
            avatarId,
            COID,
            params.tileCoordinate,
            params.LandId,
            getAvatarBombUsed(avatarId)
        );

        setAvatarCoordinate(avatarId, params.tileCoordinate);
        IGovernance(governanceContract).addCollectionOnMapNum(COID);
        IMap(IGovernance(governanceContract).mapContract())
            .redeemCollectionInboxMT(avatarId, COID);

        emit AvatarJumpIn(avatarId, COID, params.LandId, params.tileCoordinate);
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
        ownerCheck(
            params.collectionContract,
            params.tokenId,
            params.delegateWallet,
            params.vault
        )
    {
        uint256 avatarId = tokenMap[params.collectionContract][params.tokenId];
        linkCheck(avatarId, params.linkedAvatarId, params.tileCoordinate);
        uint256 COID = getAvatarCOID(avatarId);
        uint32 orgCoordinate = getAvatarCoordinate(avatarId);
        require(orgCoordinate != 0, "avatar not on map");
        IMap(IGovernance(governanceContract).mapContract()).avatarRemove(
            orgCoordinate,
            0
        );

        IMap(IGovernance(governanceContract).mapContract()).avatarSet(
            avatarId,
            COID,
            params.tileCoordinate,
            params.LandId,
            getAvatarBombUsed(avatarId)
        );

        setAvatarCoordinate(avatarId, params.tileCoordinate);

        emit AvatarMove(
            avatarId,
            COID,
            params.LandId,
            orgCoordinate,
            params.tileCoordinate
        );
    }

    /**
     * @notice throw a bomb to a tile
     * @param params OnMapParams
     */
    function bomb(
        BombParams memory params
    )
        public
        tileCheck(params.tileCoordinate)
        ownerCheck(
            params.collectionContract,
            params.tokenId,
            params.delegateWallet,
            params.vault
        )
    {
        uint256 avatarId = tokenMap[params.collectionContract][params.tokenId];
        require(avatarId > 0, "avatar not exist");
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
        for (uint256 i = 0; i < 7; i++) {
            uint256 attackAvatarId = IMap(
                IGovernance(governanceContract).mapContract()
            ).avatarRemove(params.tileCoordinate, avatarId);

            if (attackAvatarId > 0) {
                setAvatarCoordinate(attackAvatarId, 0);
                IGovernance(governanceContract).subCollectionOnMapNum(
                    getAvatarCOID(attackAvatarId)
                );
                attackAvatarIds[i] = attackAvatarId;
                victimsCoordinates[i] = params.tileCoordinate;
            }

            if (i == 0) {
                params.tileCoordinate = params.tileCoordinate.neighbor(4);
            } else {
                params.tileCoordinate = params.tileCoordinate.neighbor(i - 1);
            }
        }
        emit BombUse(
            avatarId,
            params.tileCoordinate,
            attackAvatarIds,
            victimsCoordinates
        );
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

    function linkCheck(
        uint256 avatarId,
        uint256 linkedAvatarId,
        uint32 tileCoordinate
    ) internal view {
        uint256 COID = getAvatarCOID(avatarId);
        require(COID > 0, "avatar not exist");

        if (linkedAvatarId > 0) {
            require(COID == getAvatarCOID(linkedAvatarId), "link co error");
            require(linkedAvatarId != avatarId, "link to yourself");
            if (
                tileCoordinate.distance(getAvatarCoordinate(linkedAvatarId)) > 3
            ) {
                revert linkAvatarError();
            }
        } else {
            uint256 collectionOnMapNum = IGovernance(governanceContract)
                .getCollectionOnMapNum(COID);
            if (collectionOnMapNum > 0) {
                if (
                    !(getAvatarCoordinate(avatarId) > 0 &&
                        collectionOnMapNum == 1)
                ) {
                    revert linkAvatarError();
                }
            }
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
