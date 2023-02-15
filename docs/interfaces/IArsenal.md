# Solidity API

## IArsenal

### buy

```solidity
function buy(uint256 amount) external
```

### getCurrentRound

```solidity
function getCurrentRound() external view returns (uint256)
```

### getCurrentPrice

```solidity
function getCurrentPrice() external view returns (uint256)
```

### getCurrentRoundData

```solidity
function getCurrentRoundData() external view returns (uint256 roundId, uint256 price, uint256 amoutLeft, uint256 roundStartTime, uint256 roundCloseTime)
```

### getRoundData

```solidity
function getRoundData(uint256 roundId) external view returns (uint256 price, uint256 amoutLeft, uint256 roundStartTime, uint256 roundCloseTime)
```

### getRoundPrice

```solidity
function getRoundPrice(uint256 roundId) external view returns (uint256 price)
```

### getAgio

```solidity
function getAgio(address to) external view returns (uint256 agio)
```

### redeemAgio

```solidity
function redeemAgio() external
```

