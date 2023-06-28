// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

    // Collection Id
    uint256 COIDCounter;

    mapping(uint256 => address) public COIDMap;

    /**
     * @notice record the collection's COID and number of collection nfts which is standing on the map with last 6 digit
     *
     * Collection address => uint64 mintedMT + uint48 additionalNFTPoints + uint48 COID + uint48 minted avatar num + uint48 on map nft number
     */
    mapping(address => uint256) public collectionMap;

    /** 
        avatar storage map
        avatarId => AvatarData
    */
    mapping(uint256 => AvatarData) public avatarNoumenon;

    // token map of Collection => tokenId => avatarId
    mapping(address => mapping(uint256 => uint256)) public tokenMap;

    uint256 public currentAvatarId;

    IMOPNGovernance public governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
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

    /**
     * @notice get the original owner of a NFT
     * MOPN Avatar support hot wallet protocol https://delegate.cash/ and https://warm.xyz/ to verify your NFTs
     * @param collectionContract NFT collection Contract Address
     * @param tokenId NFT tokenId
     * @return owner nft owner or nft delegate hot wallet
     */
    function ownerOf(
        address collectionContract,
        uint256 tokenId
    ) public view returns (address owner) {
        return IERC721(collectionContract).ownerOf(tokenId);
    }

    /**
     * @notice get the original owner of a avatar linked nft
     * @param avatarId avatar Id
     * @return owner nft owner or nft delegate hot wallet
     */
    function ownerOf(uint256 avatarId) public view returns (address) {
        uint256 COID = getAvatarCOID(avatarId);
        require(COID > 0, "avatar not exist");
        return
            ownerOf(
                getCollectionContract(COID),
                avatarNoumenon[avatarId].tokenId
            );
    }

    /**
     * @notice mint an avatar for a NFT
     * @param params NFTParams
     */
    function mintAvatar(NFTParams calldata params) internal returns (uint256) {
        uint256 COID = getCollectionCOID(params.collectionContract);
        if (COID == 0) {
            COID = generateCOID(params.collectionContract);
        } else {
            addCollectionAvatarNum(COID);
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
        ownerCheck(params.collectionContract, params.tokenId)
    {
        uint256 avatarId = tokenMap[params.collectionContract][params.tokenId];
        if (avatarId == 0) {
            avatarId = mintAvatar(params);
        }
        linkCheck(avatarId, linkedAvatarId, tileCoordinate);

        uint256 COID = getAvatarCOID(avatarId);
        uint32 orgCoordinate = getAvatarCoordinate(avatarId);
        if (orgCoordinate > 0) {
            IMOPNMap(governance.mapContract()).avatarRemove(orgCoordinate, 0);

            emit AvatarMove(
                avatarId,
                COID,
                LandId,
                orgCoordinate,
                tileCoordinate
            );
        } else {
            addCollectionOnMapNum(COID);
            emit AvatarJumpIn(avatarId, COID, LandId, tileCoordinate);
        }

        IMOPNMap(governance.mapContract()).avatarSet(
            avatarId,
            COID,
            tileCoordinate,
            LandId
        );

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
     * @notice use collection Id to get collection contract address
     * @param COID collection Id
     * @return contractAddress collection contract address
     */
    function getCollectionContract(uint256 COID) public view returns (address) {
        return COIDMap[COID];
    }

    /**
     * @notice use collection contract address to get collection Id
     * @param collectionContract collection contract address
     * @return COID collection Id
     */
    function getCollectionCOID(
        address collectionContract
    ) public view returns (uint256) {
        return uint48(collectionMap[collectionContract] >> 96);
    }

    /**
     * @notice batch call for {getCollectionCOID}
     * @param collectionContracts multi collection contracts
     */
    function getCollectionsCOIDs(
        address[] memory collectionContracts
    ) public view returns (uint256[] memory COIDs) {
        COIDs = new uint256[](collectionContracts.length);
        for (uint256 i = 0; i < collectionContracts.length; i++) {
            COIDs[i] = uint64(collectionMap[collectionContracts[i]] >> 96);
        }
    }

    /**
     * Generate a collection id for new collection
     * @param collectionContract collection contract adddress
     */
    function generateCOID(
        address collectionContract
    ) public returns (uint256 COID) {
        COID = getCollectionCOID(collectionContract);
        require(COID == 0, "COID exist");

        require(
            IERC165(collectionContract).supportsInterface(
                type(IERC721).interfaceId
            ),
            "not a erc721 compatible nft"
        );

        COIDCounter++;
        COIDMap[COIDCounter] = collectionContract;
        collectionMap[collectionContract] =
            (COIDCounter << 96) |
            (uint256(1) << 48);
        COID = COIDCounter;
    }

    /**
     * @notice check if this collection is in white list
     * @param collectionContract collection contract address
     * @param additionalNFTPoints additional NFT Points
     * @param proofs collection whitelist proofs
     */
    function setCollectionAdditionalNFTPoints(
        address collectionContract,
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
                            abi.encode(collectionContract, additionalNFTPoints)
                        )
                    )
                )
            ),
            "collection additionalNFTPoints can't verify"
        );
        uint256 COID = getCollectionCOID(collectionContract);
        if (COID == 0) {
            COID = generateCOID(collectionContract);
        }

        collectionMap[collectionContract] =
            (getCollectionMintedMT(COID) << 192) |
            (additionalNFTPoints << 144) |
            uint144(collectionMap[collectionContract]);

        IMOPNMiningData(governance.miningDataContract())
            .settleCollectionNFTPoint(COID);
    }

    function getCollectionAdditionalNFTPoints(
        uint256 COID
    ) public view returns (uint256) {
        return uint48(collectionMap[getCollectionContract(COID)] >> 144);
    }

    /**
     * @notice get NFT collection On map avatar number
     * @param COID collection Id
     */
    function getCollectionOnMapNum(uint256 COID) public view returns (uint256) {
        return uint48(collectionMap[getCollectionContract(COID)]);
    }

    function addCollectionOnMapNum(uint256 COID) internal {
        collectionMap[getCollectionContract(COID)]++;
    }

    function subCollectionOnMapNum(uint256 COID) internal {
        collectionMap[getCollectionContract(COID)]--;
    }

    /**
     * @notice get NFT collection minted avatar number
     * @param COID collection Id
     */
    function getCollectionAvatarNum(
        uint256 COID
    ) public view returns (uint256) {
        return uint48(collectionMap[getCollectionContract(COID)] >> 48);
    }

    function addCollectionAvatarNum(uint256 COID) internal {
        collectionMap[getCollectionContract(COID)] += uint256(1) << 48;
    }

    function getCollectionMintedMT(uint256 COID) public view returns (uint256) {
        return uint64(collectionMap[getCollectionContract(COID)] >> 192);
    }

    function addCollectionMintedMT(
        uint256 COID,
        uint256 amount
    ) public onlyMiningData {
        collectionMap[getCollectionContract(COID)] += amount << 192;
    }

    function clearCollectionMintedMT(uint256 COID) public onlyMiningData {
        collectionMap[getCollectionContract(COID)] = uint192(
            collectionMap[getCollectionContract(COID)]
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
            uint256 collectionOnMapNum = getCollectionOnMapNum(COID);
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
