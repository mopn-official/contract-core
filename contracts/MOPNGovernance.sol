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
    uint256 public chainId;

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

    address public ERC6551Registry;
    address public ERC6551AccountProxy;
    address public ERC6551AccountHelper;

    address[] public ERC6551AccountImplementations;

    function updateERC6551Contract(
        address ERC6551Registry_,
        address ERC6551AccountProxy_,
        address ERC6551AccountHelper_,
        address[] memory ERC6551AccountImplementations_
    ) public onlyOwner {
        ERC6551Registry = ERC6551Registry_;
        ERC6551AccountProxy = ERC6551AccountProxy_;
        ERC6551AccountHelper = ERC6551AccountHelper_;
        ERC6551AccountImplementations = ERC6551AccountImplementations_;
    }

    function getDefault6551AccountImplementation()
        public
        view
        returns (address)
    {
        return ERC6551AccountImplementations[0];
    }

    function setDefault6551AccountImplementation(
        address implementation
    ) public onlyOwner {
        address[] memory temps;
        if (checkImplementationExist(implementation)) {
            temps = new address[](ERC6551AccountImplementations.length);
            uint256 i = 0;
            temps[i] = implementation;
            for (uint256 k = 0; k < ERC6551AccountImplementations.length; k++) {
                if (ERC6551AccountImplementations[k] == implementation)
                    continue;
                i++;
                temps[i] = ERC6551AccountImplementations[k];
            }
        } else {
            temps = new address[](ERC6551AccountImplementations.length + 1);
            temps[0] = implementation;
            for (uint256 k = 0; k < ERC6551AccountImplementations.length; k++) {
                temps[k + 1] = ERC6551AccountImplementations[k];
            }
        }
        ERC6551AccountImplementations = temps;
    }

    function add6551AccountImplementation(
        address implementation
    ) public onlyOwner {
        require(
            !checkImplementationExist(implementation),
            "implementation exist"
        );

        ERC6551AccountImplementations.push(implementation);
    }

    function del6551AccountImplementation(
        address implementation
    ) public onlyOwner {
        require(
            checkImplementationExist(implementation),
            "implementation not exist"
        );

        address[] memory temps;
        if (ERC6551AccountImplementations.length > 1) {
            temps = new address[](ERC6551AccountImplementations.length - 1);
            uint256 i = 0;
            for (uint256 k = 0; k < ERC6551AccountImplementations.length; k++) {
                if (ERC6551AccountImplementations[k] == implementation)
                    continue;
                temps[i] = ERC6551AccountImplementations[k];
                i++;
            }
        }
        ERC6551AccountImplementations = temps;
    }

    function checkImplementationExist(
        address implementation
    ) public view returns (bool) {
        for (uint256 i = 0; i < ERC6551AccountImplementations.length; i++) {
            if (ERC6551AccountImplementations[i] == implementation) return true;
        }
        return false;
    }

    address public auctionHouseContract;
    address public mopnContract;
    address public bombContract;
    address public mtContract;
    address public pointContract;
    address public landContract;
    address public mopnDataContract;
    address public mopnCollectionVaultContract;

    function updateMOPNContracts(
        address auctionHouseContract_,
        address mopnContract_,
        address bombContract_,
        address mtContract_,
        address pointContract_,
        address landContract_,
        address mopnDataContract_,
        address mopnCollectionVaultContract_
    ) public onlyOwner {
        auctionHouseContract = auctionHouseContract_;
        mopnContract = mopnContract_;
        bombContract = bombContract_;
        mtContract = mtContract_;
        pointContract = pointContract_;
        landContract = landContract_;
        mopnDataContract = mopnDataContract_;
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
        IMOPNData(mopnDataContract).closeWhiteList();
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
        require(msg.sender == mopnDataContract, "not allowed");
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
            "initialize(address)",
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
