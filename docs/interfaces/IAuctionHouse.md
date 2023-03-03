# Solidity API

## IAuctionHouse

### buyBomb

```solidity
function buyBomb(uint256 amount) external
```

### getBombCurrentPrice

```solidity
function getBombCurrentPrice() external view returns (uint256)
```

### getBombCurrentData

```solidity
function getBombCurrentData() external view returns (uint256 roundId, uint256 price, uint256 amoutLeft, uint256 roundStartTime, uint256 roundCloseTime)
```

### getBombRoundPrice

```solidity
function getBombRoundPrice(uint256 roundId) external view returns (uint256)
```

### getAgio

```solidity
function getAgio(address to) external view returns (uint256 agio)
```

### redeemAgio

```solidity
function redeemAgio() external
```

### redeemAgioTo

```solidity
function redeemAgioTo(address to) external
```

### buyLand

```solidity
function buyLand() external
```

### getLandCurrentData

```solidity
function getLandCurrentData() external view returns (uint256 roundId, uint256 price, uint256 startTimestamp)
```

