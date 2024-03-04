// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

contract BlastLandClaim {
    ICrossDomainMessenger public immutable MESSENGER;
    address public blastLandAddress;
    address public landAddress;

    constructor(
        address _messenger,
        address _landAddress,
        address _blastLandAddress
    ){
        MESSENGER = ICrossDomainMessenger(_messenger);
        blastLandAddress = _blastLandAddress;
        landAddress = _landAddress;
    }

    function claimOnBlast(uint256[] memory tokenIds) external  {
        IERC721 land = IERC721(landAddress);
        for(uint256 i = 0; i < tokenIds.length; i++){
            require(land.ownerOf(tokenIds[i]) == msg.sender, "Not owner of token");
        }
        MESSENGER.sendMessage(
            address(blastLandAddress),
            abi.encodeCall(
                this.claim,
                (
                    msg.sender,
                    tokenIds
                )
            ),
            100000 + (100000 * tokenIds.length)
        );
    }

    function claim(address _sender, uint256[] memory tokenIds) external  {
        require(
            false,
            "nothing to claim on mainnet"
        );
    }

}
