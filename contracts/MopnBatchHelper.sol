// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IAuctionHouse.sol";
import "./interfaces/IAvatar.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMap.sol";
import "./interfaces/IMiningData.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MopnBatchHelper is Multicall, Ownable {
    IGovernance governance;
    IAuctionHouse auctionHouse;
    IAvatar avatar;
    IMap map;
    IMiningData miningData;

    constructor(address governanceContract_) {
        _setGovernanceContract(governanceContract_);
    }

    function governanceContract() public view returns (address) {
        return address(governance);
    }

    function _setGovernanceContract(address governanceContract_) internal {
        governance = IGovernance(governanceContract_);
        avatar = IAvatar(governance.avatarContract());
        map = IMap(governance.mapContract());
        miningData = IMiningData(governance.miningDataContract());
        auctionHouse = IAuctionHouse(governance.auctionHouseContract());
    }

    /**
     * @notice batch redeem avatar unclaimed minted mopn token
     * @param avatarIds avatar Ids
     * @param delegateWallets Delegate coldwallet to specify hotwallet protocol
     * @param vaults cold wallet address
     */
    function batchRedeemAvatarInboxMT(
        uint256[] memory avatarIds,
        IAvatar.DelegateWallet[] memory delegateWallets,
        address[] memory vaults
    ) public {
        require(
            delegateWallets.length == 0 ||
                delegateWallets.length == avatarIds.length,
            "delegateWallets incorrect"
        );

        if (delegateWallets.length > 0) {
            for (uint256 i = 0; i < avatarIds.length; i++) {
                miningData.redeemAvatarMT(
                    avatarIds[i],
                    delegateWallets[i],
                    vaults[i]
                );
            }
        } else {
            for (uint256 i = 0; i < avatarIds.length; i++) {
                miningData.redeemAvatarMT(
                    avatarIds[i],
                    IAvatar.DelegateWallet.None,
                    address(0)
                );
            }
        }
    }

    function batchMintAvatarMT(uint256[] memory avatarIds) public {
        miningData.settlePerNFTPointMinted();
        uint256 COID;
        for (uint256 i = 0; i < avatarIds.length; i++) {
            COID = avatar.getAvatarCOID(avatarIds[i]);
            miningData.mintCollectionMT(COID);
            miningData.mintAvatarMT(avatarIds[i]);
        }
    }

    function redeemRealtimeLandHolderMT(
        uint32 LandId,
        uint256[] memory avatarIds
    ) public {
        batchMintAvatarMT(avatarIds);
        miningData.redeemLandHolderMT(LandId);
    }

    /**
     * @notice batch redeem land holder unclaimed minted mopn token
     * @param LandIds Land Ids
     */
    function batchRedeemRealtimeLandHolderMT(
        uint32[] memory LandIds,
        uint256[][] memory avatarIds
    ) public {
        for (uint256 i = 0; i < LandIds.length; i++) {
            batchMintAvatarMT(avatarIds[i]);
        }
        miningData.batchRedeemSameLandHolderMT(LandIds);
    }

    function redeemAgioTo() public {
        auctionHouse.redeemAgioTo(msg.sender);
    }
}
