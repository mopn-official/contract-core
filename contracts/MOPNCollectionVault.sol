// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IMOPNToken.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMiningData.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNCollectionVault is ERC20, Ownable {
    uint256 public COID;

    bool public isInitialized = false;

    address public immutable governance;

    constructor(address governance_) ERC20("MOPN V-Token", "MVT") {
        governance = governance_;
    }

    function initialize(uint256 COID_) public {
        require(isInitialized == false, "contract initialzed");
        COID = COID_;
        isInitialized = true;
    }

    function stackMT(uint256 amount) public {
        uint256 mt2vscale;
        if (totalSupply() == 0) {
            mt2vscale = 10 ** decimals();
        } else {
            mt2vscale =
                totalSupply() /
                IMOPNToken(IGovernance(governance).mtContract()).balanceOf(
                    address(this)
                );
        }
        uint256 vtokenAmount = mt2vscale * amount;
        IMOPNToken(IGovernance(governance).mtContract()).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        _mint(msg.sender, vtokenAmount);
        IMiningData(IGovernance(governance).miningDataContract())
            .calcCollectionMTAW(COID);
    }

    function withdraw(uint256 amount) public {
        uint256 mtAmount;
        if (amount == totalSupply()) {
            mtAmount = IMOPNToken(IGovernance(governance).mtContract())
                .balanceOf(address(this));
        } else {
            mtAmount =
                (IMOPNToken(IGovernance(governance).mtContract()).balanceOf(
                    address(this)
                ) * amount) /
                totalSupply();
        }
        require(mtAmount > 0, "zero to withdraw");
        IMOPNToken(IGovernance(governance).mtContract()).transferFrom(
            address(this),
            msg.sender,
            mtAmount
        );
        _burn(msg.sender, amount);
        IMiningData(IGovernance(governance).miningDataContract())
            .calcCollectionMTAW(COID);
    }
}
