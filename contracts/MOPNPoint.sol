// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNData.sol";
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
        return IMOPNData(governance.mopnDataContract()).TotalMOPNPoints();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256 balance) {
        IMOPNData mopnData = IMOPNData(governance.mopnDataContract());
        balance = IMOPNBomb(governance.bombContract()).balanceOf(account, 2);
        if (mopnData.getAccountCoordinate(account) > 0) {
            balance += mopnData.getAccountTotalMOPNPoint(account);
            balance += mopnData.getCollectionMOPNPoint(
                mopnData.getAccountCollection(account)
            );
            balance += mopnData.getCollectionAdditionalMOPNPoint(
                mopnData.getAccountCollection(account)
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
