# Solidity API

## IAvatar

### getNFTAvatarId

```solidity
function getNFTAvatarId(address contractAddress, uint256 tokenId) external view returns (uint256)
```

### getAvatarCOID

```solidity
function getAvatarCOID(uint256 avatarId) external view returns (uint256)
```

get avatar collection id

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | COID colletion id |

### getAvatarTokenId

```solidity
function getAvatarTokenId(uint256 avatarId) external view returns (uint256)
```

### getAvatarBombUsed

```solidity
function getAvatarBombUsed(uint256 avatarId) external view returns (uint256)
```

get avatar bomb used number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | bomb used number |

### getAvatarCoordinate

```solidity
function getAvatarCoordinate(uint256 avatarId) external view returns (uint32)
```

get avatar on map coordinate

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint32 | tileCoordinate tile coordinate |

### NFTParams

```solidity
struct NFTParams {
  address collectionContract;
  uint256 tokenId;
  bytes32[] proofs;
  enum IAvatar.DelegateWallet delegateWallet;
  address vault;
}
```

### DelegateWallet

```solidity
enum DelegateWallet {
  None,
  DelegateCash,
  Warm
}
```

### ownerOf

```solidity
function ownerOf(uint256 avatarId, enum IAvatar.DelegateWallet delegateWallet, address vault) external view returns (address)
```

### moveTo

```solidity
function moveTo(struct IAvatar.NFTParams params, uint32 tileCoordinate, uint256 linkedAvatarId, uint32 LandId) external
```

an on map avatar move to a new tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.NFTParams | NFTParams |
| tileCoordinate | uint32 |  |
| linkedAvatarId | uint256 |  |
| LandId | uint32 |  |

### bomb

```solidity
function bomb(struct IAvatar.NFTParams params, uint32 tileCoordinate) external
```

throw a bomb to a tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.NFTParams | NFTParams |
| tileCoordinate | uint32 |  |

