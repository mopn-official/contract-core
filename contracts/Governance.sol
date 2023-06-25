// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "./interfaces/IMiningData.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IBomb.sol";
import "./interfaces/IERC20Receiver.sol";
import "./InitializedProxy.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
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
    bytes32 public whiteListRoot;

    event CollectionVaultCreated(
        uint256 indexed COID,
        address indexed collectionVault
    );

    mapping(uint256 => address) public CollectionVaults;

    /**
     * @notice update whitelist root
     * @param whiteListRoot_ white list merkle tree root
     */
    function updateWhiteList(bytes32 whiteListRoot_) public onlyOwner {
        whiteListRoot = whiteListRoot_;
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

    function closeWhiteList() public onlyOwner {
        IMiningData(miningDataContract).closeWhiteList();
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

    function createCollectionVault(uint256 COID) public returns (address) {
        require(
            IAvatar(avatarContract).getCollectionContract(COID) != address(0),
            "collection not exist"
        );
        require(CollectionVaults[COID] == address(0), "collection vault exist");

        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(uint256)",
            COID
        );
        address vaultAddress = address(
            new InitializedProxy(address(this), _initializationCalldata)
        );
        CollectionVaults[COID] = vaultAddress;
        emit CollectionVaultCreated(COID, vaultAddress);

        return vaultAddress;
    }

    function getCollectionVault(uint256 COID) public view returns (address) {
        return CollectionVaults[COID];
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

        uint256 COID = IAvatar(avatarContract).getCollectionCOID(
            collectionAddress
        );
        if (COID == 0) {
            COID = IAvatar(avatarContract).generateCOID(collectionAddress);
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
