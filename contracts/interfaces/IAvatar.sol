// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAvatar {
    /**
     * @notice Delegate Wallet Protocols
     */
    enum DelegateWallet {
        None,
        DelegateCash,
        Warm
    }

    function ownerOf(
        uint256 avatarId,
        DelegateWallet delegateWallet,
        address vault
    ) external view returns (address);

    function getAvatarCOID(uint256 avatarId) external view returns (uint256);
}
