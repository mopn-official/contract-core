// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAvatar.sol";
import "./interfaces/IMap.sol";
import "./interfaces/IAuctionHouse.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IBomb.sol";
import "./interfaces/ILand.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @title Governance of MOPN
/// @author Cyanface<cyanface@outlook.com>
/// @dev Governance is all other MOPN contract's owner
contract Governance is Multicall, Ownable {
    event MTClaimed(address indexed to, uint256 amount);

    /**
     * @notice redeem avatar unclaimed minted mopn token
     * @param avatarId avatar Id
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    function redeemAvatarInboxMT(
        uint256 avatarId,
        IAvatar.DelegateWallet delegateWallet,
        address vault
    ) public {
        require(
            msg.sender ==
                IAvatar(avatarContract).ownerOf(
                    avatarId,
                    delegateWallet,
                    vault
                ),
            "not your avatar"
        );
        IMap(mapContract).settlePerMTAWMinted();
        IMap(mapContract).mintAvatarMT(avatarId);

        uint256 amount = IMap(mapContract).claimAvatarSettledIndexMT(avatarId);
        if (amount > 0) {
            IMOPNToken(mtContract).mint(msg.sender, amount);
            emit MTClaimed(msg.sender, amount);
        }
    }

    /**
     * @notice batch redeem avatar unclaimed minted mopn token
     * @param avatarIds avatar Ids
     * @param delegateWallets Delegate coldwallet to specify hotwallet protocol
     * @param vaults cold wallet address
     */
    function batchRedeemAvatarInboxMT(
        uint256[] memory avatarIds,
        IAvatar.DelegateWallet[] memory delegateWallets,
        address[] memory vaults
    ) public {
        require(
            delegateWallets.length == 0 ||
                delegateWallets.length == avatarIds.length,
            "delegateWallets incorrect"
        );

        IMap(mapContract).settlePerMTAWMinted();
        uint256 totalamount;
        for (uint256 i = 0; i < avatarIds.length; i++) {
            if (delegateWallets.length > 0) {
                require(
                    msg.sender ==
                        IAvatar(avatarContract).ownerOf(
                            avatarIds[i],
                            delegateWallets[i],
                            vaults[i]
                        ),
                    "not your avatar"
                );
            } else {
                require(
                    msg.sender ==
                        IAvatar(avatarContract).ownerOf(
                            avatarIds[i],
                            IAvatar.DelegateWallet.None,
                            address(0)
                        ),
                    "not your avatar"
                );
            }
            IMap(mapContract).mintAvatarMT(avatarIds[i]);

            totalamount += IMap(mapContract).claimAvatarSettledIndexMT(
                avatarIds[i]
            );
        }

        if (totalamount > 0) {
            IMOPNToken(mtContract).mint(msg.sender, totalamount);
            emit MTClaimed(msg.sender, totalamount);
        }
    }

    /**
     * @notice redeem Land holder unclaimed minted mopn token
     * @param LandId MOPN Land Id
     */
    function redeemLandHolderInboxMT(uint32 LandId) public {
        require(
            msg.sender == IERC721(landContract).ownerOf(LandId),
            "not your Land"
        );
        IMap(mapContract).settlePerMTAWMinted();
        IMap(mapContract).mintLandHolderMT(LandId);

        uint256 amount = IMap(mapContract).claimLandHolderSettledIndexMT(
            LandId
        );
        if (amount > 0) {
            IMOPNToken(mtContract).mint(msg.sender, amount);
        }
    }

    bool public whiteListRequire;

    function setWhiteListRequire(bool whiteListRequire_) public onlyOwner {
        whiteListRequire = whiteListRequire_;
    }

    bytes32 public whiteListRoot;

    // Collection Id
    uint256 COIDCounter;

    mapping(uint256 => address) public COIDMap;

    /**
     * @notice record the collection's COID and number of collection nfts which is standing on the map with last 6 digit
     *
     * Collection address => COID * 1000000 + on map nft number
     */
    mapping(address => uint256) public collectionMap;

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
        return collectionMap[collectionContract] / 10 ** 16;
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
            COIDs[i] = collectionMap[collectionContracts[i]] / 10 ** 16;
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
        if (COID == 0) {
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
                COIDCounter *
                10 ** 16 +
                1000000;
            COID = COIDCounter;
        } else {
            addCollectionAvatarNum(COID);
        }
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
     * @notice get NFT collection On map avatar number
     * @param COID collection Id
     */
    function getCollectionOnMapNum(uint256 COID) public view returns (uint256) {
        return collectionMap[getCollectionContract(COID)] % 1000000;
    }

    function addCollectionOnMapNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)]++;
    }

    function subCollectionOnMapNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)]--;
    }

    /**
     * @notice get NFT collection minted avatar number
     * @param COID collection Id
     */
    function getCollectionAvatarNum(
        uint256 COID
    ) public view returns (uint256) {
        return
            (collectionMap[getCollectionContract(COID)] % 10 ** 16) / 1000000;
    }

    function addCollectionAvatarNum(uint256 COID) public onlyAvatar {
        collectionMap[getCollectionContract(COID)] += 1000000;
    }

    address public auctionHouseContract;
    address public avatarContract;
    address public bombContract;
    address public mtContract;
    address public mapContract;
    address public landContract;

    function updateMOPNContracts(
        address auctionHouseContract_,
        address avatarContract_,
        address bombContract_,
        address mtContract_,
        address mapContract_,
        address landContract_
    ) public onlyOwner {
        auctionHouseContract = auctionHouseContract_;
        avatarContract = avatarContract_;
        bombContract = bombContract_;
        mtContract = mtContract_;
        mapContract = mapContract_;
        landContract = landContract_;
    }

    // Bomb
    function mintBomb(address to, uint256 amount) public onlyAuctionHouse {
        IBomb(bombContract).mint(to, 1, amount);
    }

    function burnBomb(address from, uint256 amount) public onlyAvatar {
        IBomb(bombContract).burn(from, 1, amount);
    }

    // Land
    function mintLand(address to) public onlyAuctionHouse {
        ILand(landContract).auctionMint(to, 1);
    }

    function redeemAgio() public {
        IAuctionHouse(auctionHouseContract).redeemAgioTo(msg.sender);
    }

    ///todo remove before prod
    function giveupOwnership() public onlyOwner {
        IBomb(bombContract).transferOwnership(owner());
        IMOPNToken(mtContract).transferOwnership(owner());
    }

    modifier onlyAuctionHouse() {
        require(msg.sender == auctionHouseContract, "not allowed");
        _;
    }

    modifier onlyAvatar() {
        require(msg.sender == avatarContract, "not allowed");
        _;
    }

    modifier onlyMap() {
        require(msg.sender == mapContract, "not allowed");
        _;
    }
}
