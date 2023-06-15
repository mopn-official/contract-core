# Solidity API

## IERC20Receiver

### onERC20Received

```solidity
function onERC20Received(address _operator, address _from, uint256 _value, bytes _data) external returns (bytes4)
```

Handle the receipt of a ERC20 token(s)
The contract address is always the message sender.
     A wallet/broker/auction application MUST implement the wallet interface
     if it will accept safe transfers.

_The ERC20 smart contract calls this function on the recipient
     after a successful transfer (`safeTransferFrom`).
     This function MAY throw to revert and reject the transfer.
     Return of other than the magic value MUST result in the transaction being reverted._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operator | address | The address which called `safeTransferFrom` function |
| _from | address | The address which previously owned the token |
| _value | uint256 | amount of tokens which is being transferred |
| _data | bytes | additional data with no specified format |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` unless throwing |

