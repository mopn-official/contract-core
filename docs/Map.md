# Solidity API

## Map

_This Contract's owner must transfer to Governance Contract once it's deployed_

### tiles

```solidity
mapping(uint32 => uint256) tiles
```

### MTProducePerSecond

```solidity
uint256 MTProducePerSecond
```

### MTProduceReduceInterval

```solidity
uint256 MTProduceReduceInterval
```

### MTProduceStartTimestamp

```solidity
uint256 MTProduceStartTimestamp
```

### MTProduceData

```solidity
uint256 MTProduceData
```

uint64 PerPointMinted + uint64 LastPerPointMintedCalcTimestamp + uint64 TotalPoints

### AvatarMTs

```solidity
mapping(uint256 => uint256) AvatarMTs
```

uint64 MT Inbox + uint64 Total Minted MT + uint64 PerPointMinted + uint64 TotalPoints

### CollectionMTs

```solidity
mapping(uint256 => uint256) CollectionMTs
```

### LandHolderMTs

```solidity
mapping(uint32 => uint256) LandHolderMTs
```

### AvatarMTMinted

```solidity
event AvatarMTMinted(uint256 avatarId, uint256 amount)
```

### CollectionMTMinted

```solidity
event CollectionMTMinted(uint256 COID, uint256 amount)
```

### LandHolderMTMinted

```solidity
event LandHolderMTMinted(uint32 LandId, uint256 amount)
```

### constructor

```solidity
constructor(uint256 MTProduceStartTimestamp_) public
```

### getTileAvatar

```solidity
function getTileAvatar(uint32 tileCoordinate) public view returns (uint256)
```

get the avatar Id who is standing on a tile

#### Parameters

| Name           | Type   | Description     |
| -------------- | ------ | --------------- |
| tileCoordinate | uint32 | tile coordinate |

### getTileCOID

```solidity
function getTileCOID(uint32 tileCoordinate) public view returns (uint256)
```

get the coid of the avatar who is standing on a tile

#### Parameters

| Name           | Type   | Description     |
| -------------- | ------ | --------------- |
| tileCoordinate | uint32 | tile coordinate |

### getTileLandId

```solidity
function getTileLandId(uint32 tileCoordinate) public view returns (uint32)
```

get MOPN Land Id which a tile belongs(only have data if someone has occupied this tile before)

#### Parameters

| Name           | Type   | Description     |
| -------------- | ------ | --------------- |
| tileCoordinate | uint32 | tile coordinate |

### governanceContract

```solidity
address governanceContract
```

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

| Name           | Type    | Description                     |
| -------------- | ------- | ------------------------------- |
| avatarId       | uint256 | avatar Id                       |
| COID           | uint256 | collection Id                   |
| tileCoordinate | uint32  | tile coordinate                 |
| LandId         | uint32  | MOPN Land Id                    |
| BombUsed       | uint256 | avatar bomb used history number |

### avatarRemove

```solidity
function avatarRemove(uint32 tileCoordinate, uint256 excludeAvatarId) public returns (uint256 avatarId)
```

avatar id left a tile

_can only called by avatar contract_

#### Parameters

| Name            | Type    | Description     |
| --------------- | ------- | --------------- |
| tileCoordinate  | uint32  | tile coordinate |
| excludeAvatarId | uint256 |                 |

### getPerPointMinted

```solidity
function getPerPointMinted() public view returns (uint256)
```

get settled Per MT Allocation Weight minted mopn token number

### getLastPerPointMintedCalcTimestamp

```solidity
function getLastPerPointMintedCalcTimestamp() public view returns (uint256)
```

get last per mopn token allocation weight minted settlement timestamp

### getTotalPoints

```solidity
function getTotalPoints() public view returns (uint256)
```

get total mopn token allocation weights

### currentMTPPS

```solidity
function currentMTPPS(uint256 reduceTimes) public pure returns (uint256 MTPPB)
```

get current mt produce per second

#### Parameters

| Name        | Type    | Description  |
| ----------- | ------- | ------------ |
| reduceTimes | uint256 | reduce times |

### currentMTPPS

```solidity
function currentMTPPS() public view returns (uint256 MTPPB)
```

### settlePerPointMinted

```solidity
function settlePerPointMinted() public
```

settle per mopn token allocation weight minted mopn token

### calcPerPointMinted

```solidity
function calcPerPointMinted() public view returns (uint256)
```

### getAvatarSettledInboxMT

```solidity
function getAvatarSettledInboxMT(uint256 avatarId) public view returns (uint256)
```

get avatar settled unclaimed minted mopn token

#### Parameters

| Name     | Type    | Description |
| -------- | ------- | ----------- |
| avatarId | uint256 | avatar Id   |

### getAvatarTotalMinted

```solidity
function getAvatarTotalMinted(uint256 avatarId) public view returns (uint256)
```

### getAvatarPerPointMinted

```solidity
function getAvatarPerPointMinted(uint256 avatarId) public view returns (uint256)
```

get avatar settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name     | Type    | Description |
| -------- | ------- | ----------- |
| avatarId | uint256 | avatar Id   |

### getAvatarPoint

```solidity
function getAvatarPoint(uint256 avatarId) public view returns (uint256)
```

get avatar on map mining mopn token allocation weight

#### Parameters

| Name     | Type    | Description |
| -------- | ------- | ----------- |
| avatarId | uint256 | avatar Id   |

### mintAvatarMT

```solidity
function mintAvatarMT(uint256 avatarId) public
```

mint avatar mopn token

#### Parameters

| Name     | Type    | Description |
| -------- | ------- | ----------- |
| avatarId | uint256 | avatar Id   |

### claimAvatarSettledIndexMT

```solidity
function claimAvatarSettledIndexMT(uint256 avatarId) public returns (uint256 amount)
```

### getAvatarInboxMT

```solidity
function getAvatarInboxMT(uint256 avatarId) public view returns (uint256 inbox)
```

get avatar realtime unclaimed minted mopn token

#### Parameters

| Name     | Type    | Description |
| -------- | ------- | ----------- |
| avatarId | uint256 | avatar Id   |

### getCollectionSettledInboxMT

```solidity
function getCollectionSettledInboxMT(uint256 COID) public view returns (uint256)
```

get collection settled minted unclaimed mopn token

#### Parameters

| Name | Type    | Description   |
| ---- | ------- | ------------- |
| COID | uint256 | collection Id |

### getCollectionTotalMinted

```solidity
function getCollectionTotalMinted(uint256 COID) public view returns (uint256)
```

### getCollectionPerPointMinted

```solidity
function getCollectionPerPointMinted(uint256 COID) public view returns (uint256)
```

get collection settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name | Type    | Description   |
| ---- | ------- | ------------- |
| COID | uint256 | collection Id |

### getCollectionPoint

```solidity
function getCollectionPoint(uint256 COID) public view returns (uint256)
```

get collection on map mining mopn token allocation weight

#### Parameters

| Name | Type    | Description   |
| ---- | ------- | ------------- |
| COID | uint256 | collection Id |

### mintCollectionMT

```solidity
function mintCollectionMT(uint256 COID) public
```

mint collection mopn token

#### Parameters

| Name | Type    | Description   |
| ---- | ------- | ------------- |
| COID | uint256 | collection Id |

### getCollectionInboxMT

```solidity
function getCollectionInboxMT(uint256 COID) public view returns (uint256 inbox)
```

get collection realtime unclaimed minted mopn token

#### Parameters

| Name | Type    | Description   |
| ---- | ------- | ------------- |
| COID | uint256 | collection Id |

### claimCollectionSettledInboxMT

```solidity
function claimCollectionSettledInboxMT(uint256 avatarId, uint256 COID) public returns (uint256 amount)
```

redeem 1/collectionOnMapNFTNumber of collection unclaimed minted mopn token to a avatar
only avatar contract can calls

#### Parameters

| Name     | Type    | Description   |
| -------- | ------- | ------------- |
| avatarId | uint256 | avatar Id     |
| COID     | uint256 | collection Id |

### getLandHolderSettledInboxMT

```solidity
function getLandHolderSettledInboxMT(uint32 LandId) public view returns (uint256)
```

get Land holder settled minted unclaimed mopn token

#### Parameters

| Name   | Type   | Description  |
| ------ | ------ | ------------ |
| LandId | uint32 | MOPN Land Id |

### getLandHolderTotalMinted

```solidity
function getLandHolderTotalMinted(uint32 LandId) public view returns (uint256)
```

### getLandHolderPerPointMinted

```solidity
function getLandHolderPerPointMinted(uint32 LandId) public view returns (uint256)
```

get Land holder settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name   | Type   | Description  |
| ------ | ------ | ------------ |
| LandId | uint32 | MOPN Land Id |

### getLandHolderPoint

```solidity
function getLandHolderPoint(uint32 LandId) public view returns (uint256)
```

get Land holder on map mining mopn token allocation weight

#### Parameters

| Name   | Type   | Description  |
| ------ | ------ | ------------ |
| LandId | uint32 | MOPN Land Id |

### mintLandHolderMT

```solidity
function mintLandHolderMT(uint32 LandId) public
```

mint Land holder mopn token

#### Parameters

| Name   | Type   | Description  |
| ------ | ------ | ------------ |
| LandId | uint32 | MOPN Land Id |

### claimLandHolderSettledIndexMT

```solidity
function claimLandHolderSettledIndexMT(uint32 LandId) public returns (uint256 amount)
```

### getLandHolderInboxMT

```solidity
function getLandHolderInboxMT(uint32 LandId) public view returns (uint256 inbox)
```

get Land holder realtime unclaimed minted mopn token

#### Parameters

| Name   | Type   | Description  |
| ------ | ------ | ------------ |
| LandId | uint32 | MOPN Land Id |

### addPoint

```solidity
function addPoint(uint256 avatarId, uint256 COID, uint32 LandId, uint256 amount) public
```

### \_addPoint

```solidity
function _addPoint(uint256 avatarId, uint256 COID, uint32 LandId, uint256 amount) internal
```

add on map mining mopn token allocation weight

#### Parameters

| Name     | Type    | Description   |
| -------- | ------- | ------------- |
| avatarId | uint256 | avatar Id     |
| COID     | uint256 | collection Id |
| LandId   | uint32  | mopn Land Id  |
| amount   | uint256 | EAW amount    |

### \_subPoint

```solidity
function _subPoint(uint256 avatarId, uint256 COID, uint32 LandId) internal
```

substruct on map mining mopn token allocation weight

#### Parameters

| Name     | Type    | Description   |
| -------- | ------- | ------------- |
| avatarId | uint256 | avatar Id     |
| COID     | uint256 | collection Id |
| LandId   | uint32  | mopn Land Id  |

### checkLandId

```solidity
modifier checkLandId(uint32 tileCoordinate, uint32 LandId)
```

### onlyGovernance

```solidity
modifier onlyGovernance()
```

### onlyAvatar

```solidity
modifier onlyAvatar()
```
