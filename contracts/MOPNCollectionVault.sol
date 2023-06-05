// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

    function stackMT(uint256 amount) public {}
}
