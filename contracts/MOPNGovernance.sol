// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNBomb.sol";
import "./libraries/CollectionVaultBytecodeLib.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

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
    uint256 public vaultIndex;
    event CollectionVaultCreated(
        address indexed collectionAddress,
        address indexed collectionVault
    );

    mapping(address => address) public CollectionVaults;

    address public ERC6551Registry;
    address public ERC6551AccountProxy;
    address public ERC6551AccountHelper;

    address[] public ERC6551AccountImplementations;

    function updateERC6551Contract(
        address ERC6551Registry_,
        address ERC6551AccountProxy_,
        address ERC6551AccountHelper_
    ) public onlyOwner {
        ERC6551Registry = ERC6551Registry_;
        ERC6551AccountProxy = ERC6551AccountProxy_;
        ERC6551AccountHelper = ERC6551AccountHelper_;
    }

    function getDefault6551AccountImplementation()
        public
        view
        returns (address implementation)
    {
        if (ERC6551AccountImplementations.length > 0)
            implementation = ERC6551AccountImplementations[0];
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

    function mintMT(address to, uint256 amount) public onlyMOPN {
        IMOPNToken(mtContract).mint(to, amount);
    }

    // Bomb
    function mintBomb(address to, uint256 amount) public onlyAuctionHouse {
        IMOPNBomb(bombContract).mint(to, 1, amount);
    }

    function burnBomb(
        address from,
        uint256 amount,
        uint256 killed
    ) public onlyMOPN {
        IMOPNBomb(bombContract).burn(from, 1, amount);
        if (killed > 0) {
            IMOPNBomb(bombContract).mint(from, 2, killed);
        }
    }

    modifier onlyAuctionHouse() {
        require(msg.sender == auctionHouseContract, "not allowed");
        _;
    }

    modifier onlyMOPN() {
        require(
            msg.sender == mopnContract || msg.sender == mopnDataContract,
            "not allowed"
        );
        _;
    }

    function createCollectionVault(
        address collectionAddress
    ) public returns (address) {
        require(
            CollectionVaults[collectionAddress] == address(0),
            "collection vault exist"
        );

        address vaultAddress = _createCollectionVault(
            collectionAddress,
            vaultIndex
        );
        CollectionVaults[collectionAddress] = vaultAddress;
        emit CollectionVaultCreated(collectionAddress, vaultAddress);
        vaultIndex++;
        return vaultAddress;
    }

    function _createCollectionVault(
        address collectionAddress,
        uint256 salt
    ) internal returns (address) {
        bytes memory code = CollectionVaultBytecodeLib.getCreationCode(
            mopnCollectionVaultContract,
            collectionAddress,
            salt
        );

        address _account = Create2.computeAddress(
            bytes32(salt),
            keccak256(code)
        );

        if (_account.code.length != 0) return _account;

        _account = Create2.deploy(0, bytes32(salt), code);
        return _account;
    }

    function getCollectionVault(
        address collectionAddress
    ) public view returns (address) {
        return CollectionVaults[collectionAddress];
    }

    function computeCollectionVault(
        address collectionAddress,
        uint256 salt
    ) public view returns (address) {
        bytes memory code = CollectionVaultBytecodeLib.getCreationCode(
            mopnCollectionVaultContract,
            collectionAddress,
            salt
        );

        return Create2.computeAddress(bytes32(salt), keccak256(code));
    }
}
