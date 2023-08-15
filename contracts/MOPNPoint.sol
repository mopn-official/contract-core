// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNBomb.sol";
import "./libraries/MOPNBitMap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MOPNPoint is ERC20 {
    IMOPNGovernance governance;

    constructor(address governance_) ERC20("MOPN Point", "MP") {
        governance = IMOPNGovernance(governance_);
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return
            MOPNBitMap.TotalMOPNPoints(
                IMOPN(governance.mopnContract()).getmData()
            );
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256 balance) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        balance =
            IMOPNBomb(governance.bombContract()).balanceOf(account, 2) *
            100;
        if (MOPNBitMap.AccountCoordinate(mopn.getaData(account)) > 0) {
            balance += mopn.getAccountOnMapMOPNPoint(account);
            address collectionAddress = mopn.getAccountCollection(account);
            balance += mopn.getCollectionMOPNPoint(collectionAddress);
            balance += MOPNBitMap.CollectionAdditionalMOPNPoint(
                mopn.getcData(collectionAddress)
            );
        }
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256
    ) internal virtual override {
        require(false, "MOPN Point can't transfer");
    }
}
