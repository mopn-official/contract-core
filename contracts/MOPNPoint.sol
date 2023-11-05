// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNMiningData.sol";
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
            IMOPNMiningData(governance.miningDataContract())
                .getTotalNFTPoints();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        // todo
        return 0;
    }

    function _beforeTokenTransfer(address, address, uint256) internal virtual {
        require(false, "MOPN Point can't transfer");
    }
}
