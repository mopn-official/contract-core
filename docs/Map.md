# Solidity API

## TileHasEnemy

```solidity
error TileHasEnemy()
```

## LandIdOverflow

```solidity
error LandIdOverflow()
```

## Map

_This Contract's owner must transfer to Governance Contract once it's deployed_

### tiles

```solidity
mapping(uint32 => uint256) tiles
```

### AvatarSet

```solidity
event AvatarSet(uint256 avatarId, uint256 COID, uint32 LandId, uint32 tileCoordinate)
```

This event emit when an anvatar occupied a tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| LandId | uint32 | MOPN Land Id |
| tileCoordinate | uint32 | tile coordinate |

### AvatarRemove

```solidity
event AvatarRemove(uint256 avatarId, uint256 COID, uint32 LandId, uint32 tileCoordinate)
```

This event emit when an anvatar left a tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| LandId | uint32 | MOPN Land Id |
| tileCoordinate | uint32 | tile coordinate |

### getTileAvatar

```solidity
function getTileAvatar(uint32 tileCoordinate) public view returns (uint256)
```

get the avatar Id who is standing on a tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tileCoordinate | uint32 | tile coordinate |

### getTileCOID

```solidity
function getTileCOID(uint32 tileCoordinate) public view returns (uint256)
```

get the coid of the avatar who is standing on a tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tileCoordinate | uint32 | tile coordinate |

### getTileLandId

```solidity
function getTileLandId(uint32 tileCoordinate) public view returns (uint32)
```

get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tileCoordinate | uint32 | tile coordinate |

### getTilesAvatars

```solidity
function getTilesAvatars(uint32[] tileCoordinates) public view returns (uint256[])
```

batch call for {getTileAvatar}

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tileCoordinates | uint32[] | tile coordinate |

### setGovernanceContract

```solidity
function setGovernanceContract(address governanceContract_) public
```

### avatarSet

```solidity
function avatarSet(uint256 avatarId, uint256 COID, uint32 tileCoordinate, uint32 LandId, uint256 BombUsed) public
```

avatar id occupied a tile

_can only called by avatar contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| tileCoordinate | uint32 | tile coordinate |
| LandId | uint32 | MOPN Land Id |
| BombUsed | uint256 | avatar bomb used history number |

### avatarRemove

```solidity
function avatarRemove(uint256 avatarId, uint256 COID, uint32 tileCoordinate) public
```

avatar id left a tile

_can only called by avatar contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| tileCoordinate | uint32 | tile coordinate |

### checkLandId

```solidity
modifier checkLandId(uint32 tileCoordinate, uint32 LandId)
```

### onlyAvatar

```solidity
modifier onlyAvatar()
```

