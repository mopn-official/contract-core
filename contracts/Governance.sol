// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "./interfaces/IMiningData.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IBomb.sol";
import "./interfaces/IERC20Receiver.sol";
import "./InitializedProxy.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/

/// @title Governance of MOPN
/// @author Cyanface<cyanface@outlook.com>
/// @dev Governance is all other MOPN contract's owner
contract Governance is Multicall, Ownable {
    // Collection Id
    uint256 COIDCounter;

    mapping(uint256 => address) public COIDMap;

    mapping(uint256 => address) public CollectionVaultMap;

    /**
     * @notice record the collection's COID and number of collection nfts which is standing on the map with last 6 digit
     *
     * Collection address => uint64 mintedMT + uint64 COID + uint64 minted avatar num + uint64 on map nft number
     */
    mapping(address => uint256) public collectionMap;

    bool public whiteListRequire;

    bytes32 public whiteListRoot;

    event CollectionVaultCreated(
        uint256 indexed COID,
        address indexed collectionVault
    );

    function setWhiteListRequire(bool whiteListRequire_) public onlyOwner {
        whiteListRequire = whiteListRequire_;
    }

    /**
     * @notice check if this collection is in white list
     * @param collectionContract collection contract address
     * @param proofs collection whitelist proofs
     */
    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                proofs,
                whiteListRoot,
                keccak256(
                    bytes.concat(keccak256(abi.encode(collectionContract)))
                )
            );
    }

    /**
     * @notice update whitelist root
     * @param whiteListRoot_ white list merkle tree root
     */
    function updateWhiteList(bytes32 whiteListRoot_) public onlyOwner {
        whiteListRoot = whiteListRoot_;
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
        return uint64(collectionMap[collectionContract] >> 128);
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
            COIDs[i] = uint64(collectionMap[collectionContracts[i]] >> 128);
        }
    }

    /**
     * Generate a collection id for new collection
     * @param collectionContract collection contract adddress
     * @param proofs collection whitelist proofs
     */
    function generateCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) public returns (uint256 COID) {
        COID = getCollectionCOID(collectionContract);
        require(COID == 0, "COID exist");

        if (whiteListRequire) {
            require(
                isInWhiteList(collectionContract, proofs),
                "not in whitelist"
            );
        } else {
            require(
                IERC165(collectionContract).supportsInterface(
                    type(IERC721).interfaceId
                ),
                "not a erc721 compatible nft"
            );
        }

        COIDCounter++;
        COIDMap[COIDCounter] = collectionContract;
        collectionMap[collectionContract] =
            (COIDCounter << 128) |
            (uint256(1) << 64);
        COID = COIDCounter;
    }

    /**
     * @notice get NFT collection On map avatar number
     * @param COID collection Id
     */
    function getCollectionOnMapNum(uint256 COID) public view returns (uint256) {
        return uint64(collectionMap[getCollectionContract(COID)]);
    }

    function addCollectionOnMapNum(uint256 COID) public onlyMiningData {
        collectionMap[getCollectionContract(COID)]++;
    }

    function subCollectionOnMapNum(uint256 COID) public onlyMiningData {
        collectionMap[getCollectionContract(COID)]--;
    }

    /**
     * @notice get NFT collection minted avatar number
     * @param COID collection Id
     */
    function getCollectionAvatarNum(
        uint256 COID
    ) public view returns (uint256) {
        return uint64(collectionMap[getCollectionContract(COID)] >> 64);
    }

    function addCollectionAvatarNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)] += uint256(1) << 64;
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

    function createCollectionVault(uint256 COID) public returns (address) {
        require(COIDMap[COID] != address(0), "collection not exist");
        require(
            CollectionVaultMap[COID] == address(0),
            "collection vault exist"
        );

        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(uint256)",
            COID
        );
        address vaultAddress = address(
            new InitializedProxy(address(this), _initializationCalldata)
        );
        CollectionVaultMap[COID] = vaultAddress;
        return vaultAddress;
    }

    function getCollectionVault(uint256 COID) public view returns (address) {
        return CollectionVaultMap[COID];
    }

    address public auctionHouseContract;
    address public avatarContract;
    address public bombContract;
    address public mtContract;
    address public mapContract;
    address public landContract;
    address public miningDataContract;
    address public mopnCollectionVaultContract;

    function updateMOPNContracts(
        address auctionHouseContract_,
        address avatarContract_,
        address bombContract_,
        address mtContract_,
        address mapContract_,
        address landContract_,
        address miningDataContract_,
        address mopnCollectionVaultContract_
    ) public onlyOwner {
        auctionHouseContract = auctionHouseContract_;
        avatarContract = avatarContract_;
        bombContract = bombContract_;
        mtContract = mtContract_;
        mapContract = mapContract_;
        landContract = landContract_;
        miningDataContract = miningDataContract_;
        mopnCollectionVaultContract = mopnCollectionVaultContract_;
    }

    function mintMT(address to, uint256 amount) public onlyMiningData {
        IMOPNToken(mtContract).mint(to, amount);
    }

    // Bomb
    function mintBomb(address to, uint256 amount) public onlyAuctionHouse {
        IBomb(bombContract).mint(to, 1, amount);
    }

    function burnBomb(address from, uint256 amount) public onlyAvatar {
        IBomb(bombContract).burn(from, 1, amount);
    }

    modifier onlyAuctionHouse() {
        require(msg.sender == auctionHouseContract, "not allowed");
        _;
    }

    modifier onlyAvatar() {
        require(msg.sender == avatarContract, "not allowed");
        _;
    }

    modifier onlyMiningData() {
        require(msg.sender == miningDataContract, "not allowed");
        _;
    }

    function encodeaddress(address a) public pure returns (bytes memory) {
        return abi.encode(a, a);
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes memory data
    ) public returns (bytes4) {
        require(msg.sender == mtContract, "only accept mopn token");

        address collectionAddress;
        assembly {
            collectionAddress := mload(add(data, 20))
        }

        uint256 COID = getCollectionCOID(collectionAddress);
        bytes32[] memory temp;
        if (COID == 0) {
            COID = generateCOID(collectionAddress, temp);
        }
        address collectionVault = getCollectionVault(COID);
        if (collectionVault == address(0)) {
            collectionVault = createCollectionVault(COID);
        }

        IMOPNToken(mtContract).safeTransferFrom(
            address(this),
            collectionVault,
            value,
            "0x"
        );

        IERC20(collectionVault).transfer(
            from,
            IERC20(collectionVault).balanceOf(address(this))
        );

        return IERC20Receiver.onERC20Received.selector;
    }
}
