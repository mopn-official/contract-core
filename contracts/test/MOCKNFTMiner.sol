// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IMOCKNFT {
    function safeMint(address to, uint256 amount) external;
}

contract MOCKNFTMiner is Ownable {
    uint256 public TotalCollections;

    mapping(uint256 => address) public collectionMap;

    bool register_switch = true;

    function switchOn() public onlyOwner {
        register_switch = true;
    }

    function switchOff() public onlyOwner {
        register_switch = false;
    }

    function registerCollection() external {
        require(register_switch, "register switch off");
        TotalCollections++;
        collectionMap[TotalCollections] = msg.sender;
    }

    function mint() external {
        for (uint256 i = 1; i <= 10; i++) {
            uint256 index = (((block.prevrandao / 10 ** 30) *
                ((block.number % i) + (block.timestamp % i) + 1)) %
                TotalCollections) + 1;
            IMOCKNFT(collectionMap[index]).safeMint(msg.sender, 1);
        }
    }
}
