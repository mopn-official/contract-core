// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Proxy.sol";

interface IGov {
    function mopnCollectionVaultContract() external view returns (address);
}

/**
 * @title InitializedProxy
 * @author Anna Carroll
 */
contract InitializedProxy is Proxy {
    // address of governance contract
    address public immutable governance;

    // ======== Constructor =========

    constructor(address governance_, bytes memory _initializationCalldata) {
        governance = governance_;
        // Delegatecall into the logic contract, supplying initialization calldata
        (bool _ok, bytes memory returnData) = _implementation().delegatecall(
            _initializationCalldata
        );
        // Revert if delegatecall to implementation reverts
        require(_ok, string(returnData));
    }

    function _implementation() internal view override returns (address) {
        return IGov(governance).mopnCollectionVaultContract();
    }
}
