# Solidity API

## MiningData

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

uint64 PerNFTPointMinted + uint64 LastPerNFTPointMintedCalcTimestamp + uint64 TotalNFTPoints

### AvatarMTs

```solidity
mapping(uint256 => uint256) AvatarMTs
```

uint64 MT Inbox + uint64 CollectionPerNFTMinted + uint64 PerNFTPointMinted + uint64 TotalNFTPoints

### CollectionMTs

```solidity
mapping(uint256 => uint256) CollectionMTs
```

uint64 CollectionPerNFTMinted + uint64 PerNFTPointMinted + uint64 CollectionNFTPoints + uint64 AvatarNFTPoints

### LandHolderMTs

```solidity
mapping(uint32 => uint256) LandHolderMTs
```

uint64 MT Inbox + uint64 totalMTMinted + uint64 OnLandMiningNFT

### NFTOfferCoefficient

```solidity
uint256 NFTOfferCoefficient
```

### totalMTStaking

```solidity
uint256 totalMTStaking
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

### MTClaimed

```solidity
event MTClaimed(uint256 avatarId, uint256 COID, address to, uint256 amount)
```

### MTClaimedCollectionVault

```solidity
event MTClaimedCollectionVault(uint256 COID, uint256 amount)
```

### MTClaimedLandHolder

```solidity
event MTClaimedLandHolder(uint256 landId, uint256 amount)
```

### governance

```solidity
contract IGovernance governance
```

### constructor

```solidity
constructor(address governance_, uint256 MTProduceStartTimestamp_) public
```

### getNFTOfferCoefficient

```solidity
function getNFTOfferCoefficient() public view returns (uint256)
```

### getPerNFTPointMinted

```solidity
function getPerNFTPointMinted() public view returns (uint256)
```

get settled Per MT Allocation Weight minted mopn token number

### getLastPerNFTPointMintedCalcTimestamp

```solidity
function getLastPerNFTPointMintedCalcTimestamp() public view returns (uint256)
```

get last per mopn token allocation weight minted settlement timestamp

### getTotalNFTPoints

```solidity
function getTotalNFTPoints() public view returns (uint256)
```

get total mopn token allocation weights

### currentMTPPS

```solidity
function currentMTPPS(uint256 reduceTimes) public pure returns (uint256 MTPPB)
```

get current mt produce per second

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| reduceTimes | uint256 | reduce times |

### currentMTPPS

```solidity
function currentMTPPS() public view returns (uint256 MTPPB)
```

### settlePerNFTPointMinted

```solidity
function settlePerNFTPointMinted() public
```

settle per mopn token allocation weight minted mopn token

### calcPerNFTPointMinted

```solidity
function calcPerNFTPointMinted() public view returns (uint256)
```

### getAvatarSettledMT

```solidity
function getAvatarSettledMT(uint256 avatarId) public view returns (uint256)
```

get avatar settled unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### getAvatarCollectionPerNFTMinted

```solidity
function getAvatarCollectionPerNFTMinted(uint256 avatarId) public view returns (uint256)
```

### getAvatarPerNFTPointMinted

```solidity
function getAvatarPerNFTPointMinted(uint256 avatarId) public view returns (uint256)
```

get avatar settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### getAvatarNFTPoint

```solidity
function getAvatarNFTPoint(uint256 avatarId) public view returns (uint256)
```

get avatar on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### calcAvatarMT

```solidity
function calcAvatarMT(uint256 avatarId) public view returns (uint256 inbox)
```

get avatar realtime unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### mintAvatarMT

```solidity
function mintAvatarMT(uint256 avatarId) public returns (uint256)
```

mint avatar mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### redeemAvatarMT

```solidity
function redeemAvatarMT(uint256 avatarId, enum IAvatar.DelegateWallet delegateWallet, address vault) public
```

redeem avatar unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| delegateWallet | enum IAvatar.DelegateWallet | Delegate coldwallet to specify hotwallet protocol |
| vault | address | cold wallet address |

### getCollectionPerNFTMinted

```solidity
function getCollectionPerNFTMinted(uint256 COID) public view returns (uint256)
```

### getCollectionPerNFTPointMinted

```solidity
function getCollectionPerNFTPointMinted(uint256 COID) public view returns (uint256)
```

get collection settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### getCollectionNFTPoint

```solidity
function getCollectionNFTPoint(uint256 COID) public view returns (uint256)
```

get collection on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### getCollectionAvatarNFTPoint

```solidity
function getCollectionAvatarNFTPoint(uint256 COID) public view returns (uint256)
```

get collection avatars on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### getCollectionPoint

```solidity
function getCollectionPoint(uint256 COID) public view returns (uint256 point)
```

### calcCollectionMT

```solidity
function calcCollectionMT(uint256 COID) public view returns (uint256 inbox)
```

get collection realtime unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### mintCollectionMT

```solidity
function mintCollectionMT(uint256 COID) public
```

mint collection mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### redeemCollectionMT

```solidity
function redeemCollectionMT(uint256 COID) public
```

### settleCollectionNFTPoint

```solidity
function settleCollectionNFTPoint(uint256 COID) public
```

### settleCollectionMining

```solidity
function settleCollectionMining(uint256 COID) public
```

### getLandHolderInboxMT

```solidity
function getLandHolderInboxMT(uint32 LandId) public view returns (uint256)
```

get Land holder settled minted unclaimed mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### getLandHolderTotalMinted

```solidity
function getLandHolderTotalMinted(uint32 LandId) public view returns (uint256)
```

### getOnLandMiningNFT

```solidity
function getOnLandMiningNFT(uint32 LandId) public view returns (uint256)
```

get Land holder settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### redeemLandHolderMT

```solidity
function redeemLandHolderMT(uint32 LandId) public
```

### batchRedeemSameLandHolderMT

```solidity
function batchRedeemSameLandHolderMT(uint32[] LandIds) public
```

### addNFTPoint

```solidity
function addNFTPoint(uint256 avatarId, uint256 COID, uint256 amount) public
```

add on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| amount | uint256 | EAW amount |

### subNFTPoint

```solidity
function subNFTPoint(uint256 avatarId, uint256 COID) public
```

### _addNFTPoint

```solidity
function _addNFTPoint(uint256 avatarId, uint256 COID, uint256 amount) internal
```

add on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| amount | uint256 | EAW amount |

### _subNFTPoint

```solidity
function _subNFTPoint(uint256 avatarId, uint256 COID) internal
```

substruct on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |

### NFTOfferAcceptNotify

```solidity
function NFTOfferAcceptNotify(uint256 price) public
```

### changeTotalMTStaking

```solidity
function changeTotalMTStaking(uint256 COID, bool increase, uint256 amount) public
```

### onlyCollectionVault

```solidity
modifier onlyCollectionVault(uint256 COID)
```

### onlyAvatarOrMap

```solidity
modifier onlyAvatarOrMap()
```

