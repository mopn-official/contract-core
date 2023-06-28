// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPNAuctionHouse.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNMap.sol";
import "./interfaces/IMOPNMiningData.sol";
import "./libraries/TileMath.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MOPNBatchHelper is Multicall, Ownable {
    IMOPNGovernance governance;

    constructor(address governanceContract_) {
        _setGovernanceContract(governanceContract_);
    }

    function governanceContract() public view returns (address) {
        return address(governance);
    }

    function _setGovernanceContract(address governanceContract_) internal {
        governance = IMOPNGovernance(governanceContract_);
    }

    /**
     * @notice batch redeem avatar unclaimed minted mopn token
     * @param avatarIds avatar Ids
     */
    function batchRedeemAvatarInboxMT(uint256[] memory avatarIds) public {
        for (uint256 i = 0; i < avatarIds.length; i++) {
            IMOPNMiningData(governance.miningDataContract()).redeemAvatarMT(
                avatarIds[i]
            );
        }
    }

    function batchMintAvatarMT(uint256[] memory avatarIds) public {
        IMOPNMiningData(governance.miningDataContract())
            .settlePerNFTPointMinted();
        uint256 COID;
        for (uint256 i = 0; i < avatarIds.length; i++) {
            COID = IMOPN(governance.mopnContract()).getAvatarCOID(avatarIds[i]);
            IMOPNMiningData(governance.miningDataContract()).mintCollectionMT(
                COID
            );
            IMOPNMiningData(governance.miningDataContract()).mintAvatarMT(
                avatarIds[i]
            );
        }
    }

    function redeemRealtimeLandHolderMT(
        uint32 LandId,
        uint256[] memory avatarIds
    ) public {
        batchMintAvatarMT(avatarIds);
        IMOPNMiningData(governance.miningDataContract()).redeemLandHolderMT(
            LandId
        );
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
        IMOPNMiningData(governance.miningDataContract())
            .batchRedeemSameLandHolderMT(LandIds);
    }

    function redeemAgioTo() public {
        IMOPNAuctionHouse(governance.auctionHouseContract()).redeemAgioTo(
            msg.sender
        );
    }
}
