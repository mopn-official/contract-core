// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPNGovernance {
    function mintMT(address to, uint256 amount) external;

    function mintBomb(address to, uint256 tokenId, uint256 amount) external;

    function burnBomb(address from, uint256 tokenId, uint256 amount) external;

    function auctionHouseContract() external view returns (address);

    function mopnContract() external view returns (address);

    function bombContract() external view returns (address);

    function mtContract() external view returns (address);

    function pointContract() external view returns (address);

    function landContract() external view returns (address);

    function mopnDataContract() external view returns (address);

    function ERC6551Registry() external view returns (address);

    function ERC6551AccountProxy() external view returns (address);

    function ERC6551AccountHelper() external view returns (address);

    function getDefault6551AccountImplementation()
        external
        view
        returns (address);

    function checkImplementationExist(
        address implementation
    ) external view returns (bool);

    function createCollectionVault(
        address collectionAddress
    ) external returns (address);

    function getCollectionVaultIndex(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionVault(
        address collectionAddress
    ) external view returns (address);
}
