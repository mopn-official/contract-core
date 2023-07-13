// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./erc6551/interfaces/IERC6551Account.sol";
import "./interfaces/IMOPNAuctionHouse.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNData.sol";
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
     * @param accounts nft erc6551 accounts
     */
    function batchTransferAccountMT(address payable[] memory accounts) public {
        //todo batch transfer account mt
    }

    function batchMintAccountMT(address payable[] memory accounts) public {
        IMOPNData miningData = IMOPNData(governance.mopnDataContract());
        miningData.settlePerMOPNPointMinted();
        for (uint256 i = 0; i < accounts.length; i++) {
            (, address accountCollection, ) = IERC6551Account(accounts[i])
                .token();
            miningData.mintCollectionMT(accountCollection);
            miningData.mintAccountMT(accounts[i]);
        }
    }

    function redeemRealtimeLandHolderMT(
        uint32 LandId,
        address payable[] memory accounts
    ) public {
        batchMintAccountMT(accounts);
        IMOPNData(governance.mopnDataContract()).redeemLandHolderMT(LandId);
    }

    /**
     * @notice batch redeem land holder unclaimed minted mopn token
     * @param LandIds Land Ids
     */
    function batchRedeemRealtimeLandHolderMT(
        uint32[] memory LandIds,
        address payable[][] memory accounts
    ) public {
        for (uint256 i = 0; i < LandIds.length; i++) {
            batchMintAccountMT(accounts[i]);
        }
        IMOPNData(governance.mopnDataContract()).batchRedeemSameLandHolderMT(
            LandIds
        );
    }

    function redeemAgioTo() public {
        IMOPNAuctionHouse(governance.auctionHouseContract()).redeemAgioTo(
            msg.sender
        );
    }
}
