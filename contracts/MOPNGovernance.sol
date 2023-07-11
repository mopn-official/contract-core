// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNData.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNBomb.sol";
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
contract MOPNGovernance is Multicall, Ownable {
    uint256 chainId;

    bytes32 public whiteListRoot;

    event CollectionVaultCreated(
        address indexed collectionAddress,
        address indexed collectionVault
    );

    mapping(address => address) public CollectionVaults;

    constructor(uint256 chainId_) {
        chainId = chainId_;
    }

    /**
     * @notice update whitelist root
     * @param whiteListRoot_ white list merkle tree root
     */
    function updateWhiteList(bytes32 whiteListRoot_) public onlyOwner {
        whiteListRoot = whiteListRoot_;
    }

    address public erc6551Registry;
    address public erc6551AccountImplementation;

    function updateERC6551Contract(
        address erc6551Registry_,
        address erc6551AccountImplementation_
    ) public onlyOwner {
        erc6551Registry = erc6551Registry_;
        erc6551AccountImplementation = erc6551AccountImplementation_;
    }

    address public delegateCashContract;

    function updateDelegateCashContract(
        address delegateCashContract_
    ) public onlyOwner {
        delegateCashContract = delegateCashContract_;
    }

    address public auctionHouseContract;
    address public mopnContract;
    address public bombContract;
    address public mtContract;
    address public pointContract;
    address public mapContract;
    address public landContract;
    address public miningDataContract;
    address public mopnCollectionVaultContract;

    function updateMOPNContracts(
        address auctionHouseContract_,
        address mopnContract_,
        address bombContract_,
        address mtContract_,
        address pointContract_,
        address mapContract_,
        address landContract_,
        address miningDataContract_,
        address mopnCollectionVaultContract_
    ) public onlyOwner {
        auctionHouseContract = auctionHouseContract_;
        mopnContract = mopnContract_;
        bombContract = bombContract_;
        mtContract = mtContract_;
        pointContract = pointContract_;
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
        IMOPNBomb(bombContract).mint(to, 1, amount);
    }

    function burnBomb(address from, uint256 amount) public onlyAvatar {
        IMOPNBomb(bombContract).burn(from, 1, amount);
        IMOPNBomb(bombContract).mint(from, 2, amount);
    }

    function closeWhiteList() public onlyOwner {
        IMOPNData(miningDataContract).closeWhiteList();
    }

    modifier onlyAuctionHouse() {
        require(msg.sender == auctionHouseContract, "not allowed");
        _;
    }

    modifier onlyAvatar() {
        require(msg.sender == mopnContract, "not allowed");
        _;
    }

    modifier onlyMiningData() {
        require(msg.sender == miningDataContract, "not allowed");
        _;
    }

    function createCollectionVault(
        address collectionAddress
    ) public returns (address) {
        require(
            CollectionVaults[collectionAddress] == address(0),
            "collection vault exist"
        );

        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(uint256)",
            collectionAddress
        );
        address vaultAddress = address(
            new InitializedProxy(address(this), _initializationCalldata)
        );
        CollectionVaults[collectionAddress] = vaultAddress;
        emit CollectionVaultCreated(collectionAddress, vaultAddress);

        return vaultAddress;
    }

    function getCollectionVault(
        address collectionAddress
    ) public view returns (address) {
        return CollectionVaults[collectionAddress];
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

        address collectionVault = getCollectionVault(collectionAddress);
        if (collectionVault == address(0)) {
            collectionVault = createCollectionVault(collectionAddress);
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
