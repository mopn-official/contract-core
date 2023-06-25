// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNToken is ERC20Burnable, Ownable {
    /**
     * @dev Magic value to be returned by ERC20Receiver upon successful reception of token(s)
     * @dev Equal to `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`,
     *      which can be also obtained as `ERC20Receiver(0).onERC20Received.selector`
     */
    bytes4 private constant ERC20_RECEIVED = 0x4fc35859;

    constructor() ERC20("MOPN Token", "MT") {}

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) public {
        if (_from == msg.sender) {
            _transfer(_from, _to, _value);
        } else {
            transferFrom(_from, _to, _value);
        }

        // after the successful transfer – check if receiver supports
        // ERC20Receiver and execute a callback handler `onERC20Received`,
        // reverting whole transaction on any error:
        // check if receiver `_to` supports ERC20Receiver interface
        if (_to.code.length > 0) {
            // if `_to` is a contract – execute onERC20Received
            bytes4 response = IERC20Receiver(_to).onERC20Received(
                msg.sender,
                _from,
                _value,
                _data
            );

            // expected response is ERC20_RECEIVED
            require(response == ERC20_RECEIVED);
        }
    }
}
