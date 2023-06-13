# Solidity API

## IMiningData

### getNFTOfferCoefficient

```solidity
function getNFTOfferCoefficient() external view returns (uint256)
```

### addNFTPoint

```solidity
function addNFTPoint(uint256 avatarId, uint256 COID, uint256 amount) external
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
function subNFTPoint(uint256 avatarId, uint256 COID) external
```

### settlePerNFTPointMinted

```solidity
function settlePerNFTPointMinted() external
```

### getAvatarNFTPoint

```solidity
function getAvatarNFTPoint(uint256 avatarId) external view returns (uint256)
```

### calcAvatarMT

```solidity
function calcAvatarMT(uint256 avatarId) external view returns (uint256 inbox)
```

### mintAvatarMT

```solidity
function mintAvatarMT(uint256 avatarId) external returns (uint256)
```

### redeemAvatarMT

```solidity
function redeemAvatarMT(uint256 avatarId, enum IAvatar.DelegateWallet delegateWallet, address vault) external
```

### getCollectionNFTPoint

```solidity
function getCollectionNFTPoint(uint256 COID) external view returns (uint256)
```

### getCollectionAvatarNFTPoint

```solidity
function getCollectionAvatarNFTPoint(uint256 COID) external view returns (uint256)
```

### getCollectionPoint

```solidity
function getCollectionPoint(uint256 COID) external view returns (uint256)
```

### calcCollectionMT

```solidity
function calcCollectionMT(uint256 COID) external view returns (uint256)
```

### mintCollectionMT

```solidity
function mintCollectionMT(uint256 COID) external
```

### redeemCollectionMT

```solidity
function redeemCollectionMT(uint256 COID) external
```

### settleCollectionMining

```solidity
function settleCollectionMining(uint256 COID) external
```

### settleCollectionNFTPoint

```solidity
function settleCollectionNFTPoint(uint256 COID) external
```

### getLandHolderInboxMT

```solidity
function getLandHolderInboxMT(uint32 LandId) external view returns (uint256 inbox)
```

get Land holder realtime unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### getLandHolderTotalMinted

```solidity
function getLandHolderTotalMinted(uint32 LandId) external view returns (uint256)
```

### redeemLandHolderMT

```solidity
function redeemLandHolderMT(uint32 LandId) external
```

### batchRedeemSameLandHolderMT

```solidity
function batchRedeemSameLandHolderMT(uint32[] LandIds) external
```

### changeTotalMTStaking

```solidity
function changeTotalMTStaking(uint256 COID, bool increase, uint256 amount) external
```

### NFTOfferAcceptNotify

```solidity
function NFTOfferAcceptNotify(uint256 price) external
```

