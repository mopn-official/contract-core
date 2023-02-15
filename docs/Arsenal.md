# Solidity API

## Arsenal

_This Contract's owner must transfer to Governance Contract once it's deployed_

### governanceContract

```solidity
address governanceContract
```

### roundTime

```solidity
uint256 roundTime
```

### roundProduce

```solidity
uint256 roundProduce
```

### startUnixRound

```solidity
uint256 startUnixRound
```

### startPrice

```solidity
uint256 startPrice
```

### roundData

```solidity
mapping(uint256 => uint256) roundData
```

_record the number of bombs that already sold and it's deal price by round
roundId => DealPrice * 1000000 + roundSold_

### walletData

```solidity
mapping(address => uint256) walletData
```

_record the last participate round auction data
wallet address => total spend * 10 ** 17 + auction amount * 10 ** 11 + roundId * 10 + agio redeem status_

### lastRound

```solidity
uint256 lastRound
```

_last active round and it's settlement status
round Id * 10 + settlement status_

### setGovernanceContract

```solidity
function setGovernanceContract(address governanceContract_) public
```

_set the governance contract address
this function also get the energy contract from the governances_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| governanceContract_ | address | Governance Contract Address |

### checkCurrentRoundFinish

```solidity
function checkCurrentRoundFinish() public view returns (bool finish)
```

_check if the current round is finish_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| finish | bool | finish status |

### buy

```solidity
function buy(uint256 amount) public
```

buy the amount of bombs at current block's price

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | the amount of bombs |

### getCurrentRound

```solidity
function getCurrentRound() public view returns (uint256)
```

get current Round Id

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | roundId round Id |

### getCurrentPrice

```solidity
function getCurrentPrice() public view returns (uint256 price)
```

get the current auction price by block.timestamp

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | uint256 | current auction price |

### getCurrentRoundData

```solidity
function getCurrentRoundData() public view returns (uint256 roundId, uint256 price, uint256 amoutLeft, uint256 roundStartTime, uint256 roundCloseTime)
```

a set of current round data

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundId | uint256 | round Id of current round |
| price | uint256 |  |
| amoutLeft | uint256 |  |
| roundStartTime | uint256 | round start timestamp |
| roundCloseTime | uint256 | round close timestamp |

### getRoundData

```solidity
function getRoundData(uint256 roundId) public view returns (uint256 price, uint256 amoutLeft, uint256 roundStartTime, uint256 roundCloseTime)
```

a set of Specified round data

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundId | uint256 | round Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | uint256 | final price |
| amoutLeft | uint256 |  |
| roundStartTime | uint256 | round start timestamp |
| roundCloseTime | uint256 | round close timestamp |

### getRoundPrice

```solidity
function getRoundPrice(uint256 roundId) public view returns (uint256 price)
```

get Round Deal Price

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundId | uint256 | round Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | uint256 | round Deal Price |

### getRoundSold

```solidity
function getRoundSold(uint256 roundId) public view returns (uint256)
```

get Round Sold amount

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundId | uint256 | round Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | amount round sold amount |

### settleLastRound

```solidity
function settleLastRound() public
```

make the last round settlement if it's finished

### getAgio

```solidity
function getAgio(address to) public view returns (uint256 agio)
```

get the Specified wallet's agio amount

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | the wallet address who is getting the agio |

### redeemAgio

```solidity
function redeemAgio() public
```

redeem the caller's agio

