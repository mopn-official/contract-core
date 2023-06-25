// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "./interfaces/IAvatar.sol";
import "./interfaces/IMiningData.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IERC20Receiver.sol";
import "./InitializedProxy.sol";
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
contract MOPNCollectionPoints is Multicall, Ownable {
    mapping(uint256 => address) public CollectionVaults;

    event CollectionVaultCreated(
        uint256 indexed COID,
        address indexed collectionVault
    );

    IGovernance public governance;

    constructor(address governance_) {
        governance = IGovernance(governance_);
    }

    function createCollectionVault(uint256 COID) public returns (address) {
        require(
            IAvatar(governance.avatarContract()).getCollectionContract(COID) !=
                address(0),
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
        require(
            msg.sender == governance.mtContract(),
            "only accept mopn token"
        );

        address collectionAddress;
        assembly {
            collectionAddress := mload(add(data, 20))
        }

        uint256 COID = IAvatar(governance.avatarContract()).getCollectionCOID(
            collectionAddress
        );
        if (COID == 0) {
            COID = IAvatar(governance.avatarContract()).generateCOID(
                collectionAddress
            );
        }
        address collectionVault = getCollectionVault(COID);
        if (collectionVault == address(0)) {
            collectionVault = createCollectionVault(COID);
        }

        IMOPNToken(governance.mtContract()).safeTransferFrom(
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
