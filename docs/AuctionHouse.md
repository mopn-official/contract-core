# Solidity API

## AuctionHouse

_This Contract's owner must transfer to Governance Contract once it's deployed_

### governanceContract

```solidity
address governanceContract
```

### bombRoundProduce

```solidity
uint256 bombRoundProduce
```

### bombRound

```solidity
uint256 bombRound
```

roundId * 10 ** 14 + startTimestamp * 10 ** 3 + round sold

_last active round and it's start timestamp and it's settlement status_

### bombRoundData

```solidity
mapping(uint256 => uint256) bombRoundData
```

_record the deal price by round
roundId => DealPrice_

### bombWalletData

```solidity
mapping(address => uint256) bombWalletData
```

_record the last participate round auction data
wallet address => total spend * 10 ** 14 + auction amount * 10 ** 11 + roundId * 10 + agio redeem status_

### BombSold

```solidity
event BombSold(address buyer, uint256 amount, uint256 price)
```

### constructor

```solidity
constructor(uint256 bombStartTimestamp, uint256 landStartTimestamp) public
```

### setGovernanceContract

```solidity
function setGovernanceContract(address governanceContract_) public
```

_set the governance contract address
this function also get the mopn token contract from the governances_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| governanceContract_ | address | Governance Contract Address |

### buyBomb

```solidity
function buyBomb(uint256 amount) public
```

buy the amount of bombs at current block's price

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | the amount of bombs |

### getBombRoundId

```solidity
function getBombRoundId() public view returns (uint256 roundId)
```

get current Round Id

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundId | uint256 | round Id |

### getBombRoundStartTimestamp

```solidity
function getBombRoundStartTimestamp() public view returns (uint256 startTimestamp)
```

### getBombRoundSold

```solidity
function getBombRoundSold() public view returns (uint256)
```

### getBombWalletTotalSpend

```solidity
function getBombWalletTotalSpend(address wallet) public view returns (uint256)
```

### getBombWalletAuctionAmount

```solidity
function getBombWalletAuctionAmount(address wallet) public view returns (uint256)
```

### getBombWalletRoundId

```solidity
function getBombWalletRoundId(address wallet) public view returns (uint256)
```

### getBombWalletAgioRedeemStatus

```solidity
function getBombWalletAgioRedeemStatus(address wallet) public view returns (uint256)
```

### getBombRoundPrice

```solidity
function getBombRoundPrice(uint256 roundId) public view returns (uint256)
```

### getBombCurrentPrice

```solidity
function getBombCurrentPrice() public view returns (uint256)
```

get the current auction price by block.timestamp

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | price current auction price |

### bombPriceMap

```solidity
uint256[] bombPriceMap
```

### bombZeroTrigger

```solidity
uint256 bombZeroTrigger
```

### getBombPrice

```solidity
function getBombPrice(uint256 reduceTimes) public view returns (uint256 price)
```

### getBombCurrentData

```solidity
function getBombCurrentData() public view returns (uint256 roundId, uint256 price, uint256 amoutLeft, uint256 roundStartTime)
```

a set of current round data

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundId | uint256 | round Id of current round |
| price | uint256 |  |
| amoutLeft | uint256 |  |
| roundStartTime | uint256 | round start timestamp |

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

### redeemAgioTo

```solidity
function redeemAgioTo(address to) public
```

### _redeemAgio

```solidity
function _redeemAgio(address to) internal
```

### settleBombPreviousRound

```solidity
function settleBombPreviousRound(uint256 roundId, uint256 price) internal
```

make the last round settlement

### landRound

```solidity
uint256 landRound
```

roundId * 10 ** 11 + startTimestamp

_last active round's start timestamp_

### getLandRoundId

```solidity
function getLandRoundId() public view returns (uint256 roundId)
```

get current Land Round Id

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundId | uint256 | round Id |

### getLandRoundStartTimestamp

```solidity
function getLandRoundStartTimestamp() public view returns (uint256 startTimestamp)
```

### buyLand

```solidity
function buyLand() public
```

buy one land at current block's price

### getLandCurrentPrice

```solidity
function getLandCurrentPrice() public view returns (uint256)
```

get the current auction price for land

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | price current auction price |

### landPriceMap

```solidity
uint256[] landPriceMap
```

### landZeroTrigger

```solidity
uint256 landZeroTrigger
```

### getLandPrice

```solidity
function getLandPrice(uint256 reduceTimes) public view returns (uint256 price)
```

### getLandCurrentData

```solidity
function getLandCurrentData() public view returns (uint256 roundId, uint256 price, uint256 startTimestamp)
```

a set of current round data

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| roundId | uint256 | round Id of current round |
| price | uint256 |  |
| startTimestamp | uint256 |  |

