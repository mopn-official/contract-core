// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGovernance {
    /**
     * @notice Delegate Wallet Protocols
     */
    enum DelegateWallet {
        None,
        DelegateCash,
        Warm
    }

    function getAvatarInboxMT(
        uint256 avatarId
    ) external view returns (uint256 inbox);

    /**
     * @notice redeem avatar unclaimed minted MOPN Tokens
     * @param avatarId avatar Id
     * @param delegateWallet Delegate coldwallet to specify hotwallet protocol
     * @param vault cold wallet address
     */
    function redeemAvatarInboxMT(
        uint256 avatarId,
        DelegateWallet delegateWallet,
        address vault
    ) external;

    function getCollectionInboxMT(
        uint256 COID
    ) external view returns (uint256 inbox);

    function redeemCollectionInboxMT(uint256 avatarId, uint256 COID) external;

    function getLandHolderInboxMT(
        uint32 LandId
    ) external view returns (uint256 inbox);

    function redeemLandHolderInboxMT(uint32 LandId) external;

    function getLandHolderRedeemed(
        uint32 LandId
    ) external view returns (uint256);

    function getCollectionInfo(
        uint256 COID
    )
        external
        view
        returns (
            address collectionAddress,
            uint256 onMapNum,
            uint256 avatarNum,
            uint256 totalEAWs,
            uint256 totalMinted
        );

    function getCollectionContract(
        uint256 COID
    ) external view returns (address);

    function getCollectionCOID(
        address collectionContract
    ) external view returns (uint256);

    function getCollectionsCOIDs(
        address[] memory collectionContracts
    ) external view returns (uint256[] memory COIDs);

    function generateCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) external returns (uint256);

    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) external view returns (bool);

    function updateWhiteList(bytes32 whiteListRoot_) external;

    function addCollectionOnMapNum(uint256 COID) external;

    function subCollectionOnMapNum(uint256 COID) external;

    function getCollectionOnMapNum(
        uint256 COID
    ) external view returns (uint256);

    function addMTAW(
        uint256 avatarId,
        uint256 COID,
        uint32 LandId,
        uint256 amount
    ) external;

    function subMTAW(uint256 avatarId, uint256 COID, uint32 LandId) external;

    function mintBomb(address to, uint256 amount) external;

    function burnBomb(
        address from,
        uint256 amount,
        uint256 avatarId,
        uint256 COID,
        uint32 LandId
    ) external;

    function redeemAgio() external;

    function mintLand(address to) external;

    function avatarContract() external view returns (address);

    function bombContract() external view returns (address);

    function mtContract() external view returns (address);

    function mapContract() external view returns (address);

    function landContract() external view returns (address);
}
