# Solidity API

## IMap

### avatarSet

```solidity
function avatarSet(uint256 avatarId, uint256 COID, uint32 tileCoordinate, uint32 LandId, uint256 BombUsed) external
```

### avatarRemove

```solidity
function avatarRemove(uint32 tileCoordinate, uint256 excludeAvatarId) external returns (uint256)
```

### getTileAvatar

```solidity
function getTileAvatar(uint32 tileCoordinate) external view returns (uint256)
```

### getTilesAvatars

```solidity
function getTilesAvatars(uint32[] tileCoordinates) external view returns (uint256[])
```

### getTileCOID

```solidity
function getTileCOID(uint32 tileCoordinate) external view returns (uint256)
```

### getTileLandId

```solidity
function getTileLandId(uint32 tileCoordinate) external view returns (uint32)
```

