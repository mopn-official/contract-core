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

    constructor(address governanceContract_) {
        _setGovernanceContract(governanceContract_);
    }

    function governanceContract() public view returns (address) {
        return address(governance);
    }

    function _setGovernanceContract(address governanceContract_) internal {
        governance = IGovernance(governanceContract_);
    }

    /**
     * @notice batch redeem avatar unclaimed minted mopn token
     * @param avatarIds avatar Ids
     */
    function batchRedeemAvatarInboxMT(uint256[] memory avatarIds) public {
        for (uint256 i = 0; i < avatarIds.length; i++) {
            IMiningData(governance.miningDataContract()).redeemAvatarMT(
                avatarIds[i]
            );
        }
    }

    function batchMintAvatarMT(uint256[] memory avatarIds) public {
        IMiningData(governance.miningDataContract()).settlePerNFTPointMinted();
        uint256 COID;
        for (uint256 i = 0; i < avatarIds.length; i++) {
            COID = IAvatar(governance.avatarContract()).getAvatarCOID(
                avatarIds[i]
            );
            IMiningData(governance.miningDataContract()).mintCollectionMT(COID);
            IMiningData(governance.miningDataContract()).mintAvatarMT(
                avatarIds[i]
            );
        }
    }

    function redeemRealtimeLandHolderMT(
        uint32 LandId,
        uint256[] memory avatarIds
    ) public {
        batchMintAvatarMT(avatarIds);
        IMiningData(governance.miningDataContract()).redeemLandHolderMT(LandId);
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
        IMiningData(governance.miningDataContract())
            .batchRedeemSameLandHolderMT(LandIds);
    }

    function redeemAgioTo() public {
        IAuctionHouse(governance.auctionHouseContract()).redeemAgioTo(
            msg.sender
        );
    }
}
