// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

contract MOCKNFTFactory {
    error InitializationFailed();

    event MockCollectionCreated(address collectionAddress);

    function createNewMockCollection(
        address implementation,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        bytes memory code = getCreationCode(implementation, salt);

        address _mock = Create2.computeAddress(bytes32(salt), keccak256(code));

        if (_mock.code.length != 0) return _mock;

        _mock = Create2.deploy(0, bytes32(salt), code);

        if (initData.length != 0) {
            (bool success, ) = _mock.call(initData);
            if (!success) revert InitializationFailed();
        }

        emit MockCollectionCreated(_mock);

        return _mock;
    }

    function getCreationCode(
        address implementation_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_)
            );
    }
}
