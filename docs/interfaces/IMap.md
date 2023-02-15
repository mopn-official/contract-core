# Solidity API

## IMap

### avatarSet

```solidity
function avatarSet(uint256 avatarId, uint256 COID, uint32 tileCoordinate, uint32 PassId, uint256 BombUsed) external
```

### avatarRemove

```solidity
function avatarRemove(uint256 avatarId, uint256 COID, uint32 tileCoordinate) external
```

### getTileAvatar

```solidity
function getTileAvatar(uint32 tileCoordinate) external view returns (uint256)
```

### getTilesAvatars

```solidity
function getTilesAvatars(uint32[] tileCoordinates) external view returns (uint256[])
```

### getTilePassId

```solidity
function getTilePassId(uint32 tileCoordinate) external view returns (uint32)
```

