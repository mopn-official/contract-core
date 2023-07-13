// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPNGovernance {
    function updateWhiteList(bytes32 whiteListRoot_) external;

    function mintMT(address to, uint256 amount) external;

    function mintBomb(address to, uint256 amount) external;

    function burnBomb(address from, uint256 amount) external;

    function whiteListRoot() external view returns (bytes32);

    function auctionHouseContract() external view returns (address);

    function mopnContract() external view returns (address);

    function bombContract() external view returns (address);

    function mtContract() external view returns (address);

    function pointContract() external view returns (address);

    function landContract() external view returns (address);

    function erc6551Registry() external view returns (address);

    function erc6551AccountImplementation() external view returns (address);

    function mopnErc6551AccountProxy() external view returns (address);

    function mopnDataContract() external view returns (address);

    function createCollectionVault(
        address collectionAddress
    ) external returns (address);

    function getCollectionVault(
        address collectionAddress
    ) external view returns (address);

    function chainId() external view returns (uint256);
}
