// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IPassMetaDataRender.sol";
import "./libraries/NFTMetaData.sol";

contract PassMetaDataRender is IMOPNPassMetaDataRender {
    IMap private Map;
    IGovernance private Governance;

    /**
     * @dev set the governance contract address
     * @dev this function also get the Map contract from the governances
     * @param governanceContract_ Governance Contract Address
     */
    function setGovernanceContract(address governanceContract_) public {
        Governance = IGovernance(governanceContract_);
        Map = IMap(Governance.mapContract());
    }

    function constructTokenURI(
        uint256 PassId
    ) public view returns (string memory) {
        return NFTMetaData.constructTokenURI(uint32(PassId), PassId);
    }
}
