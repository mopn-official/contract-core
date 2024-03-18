// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {FacetCommons} from "./FacetCommons.sol";
import {LibMOPN} from "../libraries/LibMOPN.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Events} from "../libraries/Events.sol";
import "../interfaces/IMOPNToken.sol";
import "../interfaces/IMOPNBomb.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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
contract MOPNGovernanceFacet is FacetCommons {
    function updateERC6551Contract(address ERC6551Registry_, address ERC6551AccountProxy_, address ERC6551AccountHelper_) public {
        LibDiamond.enforceIsContractOwner();
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        s.ERC6551Registry = ERC6551Registry_;
        s.ERC6551AccountProxy = ERC6551AccountProxy_;
        s.ERC6551AccountHelper = ERC6551AccountHelper_;
    }

    function updateMOPNContracts(address bombContract_, address tokenContract_, address landContract_, address vaultContract_) public {
        LibDiamond.enforceIsContractOwner();
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        s.bombContract = bombContract_;
        s.tokenContract = tokenContract_;
        s.landContract = landContract_;
        s.vaultContract = vaultContract_;
    }

    function whiteListRootUpdate(bytes32 root) public {
        LibDiamond.enforceIsContractOperator();
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        s.whiteListRoot = root;
    }

    function createCollectionVault(address collectionAddress) public returns (address) {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        require(s.CDs[collectionAddress].vaultAddress == address(0), "collection vault exist");

        address vaultAddress = _createCollectionVault(collectionAddress);
        s.CDs[collectionAddress].vaultAddress = vaultAddress;
        s.CDs[collectionAddress].vaultIndex = s.vaultIndex;
        emit Events.CollectionVaultCreated(collectionAddress, vaultAddress);
        s.vaultIndex++;
        return vaultAddress;
    }

    function _createCollectionVault(address collectionAddress) internal returns (address) {
        bytes memory code = getCollectionVaultCreationCode(LibMOPN.mopnStorage().vaultContract, collectionAddress, 0);
        address _account = Create2.computeAddress(bytes32(0), keccak256(code));
        if (_account.code.length != 0) return _account;
        return Create2.deploy(0, bytes32(0), code);
    }

    function computeCollectionVault(address collectionAddress) public view returns (address) {
        return
            Create2.computeAddress(bytes32(0), keccak256(getCollectionVaultCreationCode(LibMOPN.mopnStorage().vaultContract, collectionAddress, 0)));
    }

    function getCollectionVaultCreationCode(address implementation_, address collectionAddress_, uint256 salt_) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_, collectionAddress_)
            );
    }
}
