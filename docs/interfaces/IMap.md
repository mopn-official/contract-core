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

### getTileCOID

```solidity
function getTileCOID(uint32 tileCoordinate) external view returns (uint256)
```

### getTileLandId

```solidity
function getTileLandId(uint32 tileCoordinate) external view returns (uint32)
```

### addPoint

```solidity
function addPoint(uint256 avatarId, uint256 COID, uint32 LandId, uint256 amount) external
```

add on map mining mopn token allocation weight

#### Parameters

| Name     | Type    | Description   |
| -------- | ------- | ------------- |
| avatarId | uint256 | avatar Id     |
| COID     | uint256 | collection Id |
| LandId   | uint32  | mopn Land Id  |
| amount   | uint256 | EAW amount    |

### settlePerPointMinted

```solidity
function settlePerPointMinted() external
```

### mintAvatarMT

```solidity
function mintAvatarMT(uint256 avatarId) external
```

### claimAvatarSettledIndexMT

```solidity
function claimAvatarSettledIndexMT(uint256 avatarId) external returns (uint256 amount)
```

### getAvatarInboxMT

```solidity
function getAvatarInboxMT(uint256 avatarId) external view returns (uint256 inbox)
```

### getAvatarTotalMinted

```solidity
function getAvatarTotalMinted(uint256 avatarId) external view returns (uint256)
```

### getAvatarPoint

```solidity
function getAvatarPoint(uint256 avatarId) external view returns (uint256)
```

### getCollectionInboxMT

```solidity
function getCollectionInboxMT(uint256 COID) external view returns (uint256 inbox)
```

### getCollectionPoint

```solidity
function getCollectionPoint(uint256 COID) external view returns (uint256)
```

### getCollectionTotalMinted

```solidity
function getCollectionTotalMinted(uint256 COID) external view returns (uint256)
```

### claimCollectionSettledInboxMT

```solidity
function claimCollectionSettledInboxMT(uint256 avatarId, uint256 COID) external returns (uint256)
```

### getLandHolderInboxMT

```solidity
function getLandHolderInboxMT(uint32 LandId) external view returns (uint256 inbox)
```

get Land holder realtime unclaimed minted mopn token

#### Parameters

| Name   | Type   | Description  |
| ------ | ------ | ------------ |
| LandId | uint32 | MOPN Land Id |

### getLandHolderTotalMinted

```solidity
function getLandHolderTotalMinted(uint32 LandId) external view returns (uint256)
```

### getLandHolderPoint

```solidity
function getLandHolderPoint(uint32 LandId) external view returns (uint256)
```

### mintLandHolderMT

```solidity
function mintLandHolderMT(uint32 LandId) external
```

### claimLandHolderSettledIndexMT

```solidity
function claimLandHolderSettledIndexMT(uint32 LandId) external returns (uint256 amount)
```

### transferOwnership

```solidity
function transferOwnership(address newOwner) external
```
