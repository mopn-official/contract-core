// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNData.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNBomb is ERC1155, Multicall, Ownable {
    IMOPNGovernance governance;

    constructor(address governance_) ERC1155("") {
        governance = IMOPNGovernance(governance_);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyGovernance {
        _mint(to, id, amount, "");
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyGovernance {
        _burn(from, id, amount);
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        IMOPNData miningData = IMOPNData(governance.mopnDataContract());
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == 2) {
                if (miningData.getAccountCoordinate(from) > 0) {
                    miningData.subMOPNPoint(from, amounts[i]);
                }
                if (miningData.getAccountCoordinate(to) > 0) {
                    miningData.addMOPNPoint(to, amounts[i]);
                }
            }
        }
    }

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "not allowed");
        _;
    }
}
