# Solidity API

## IAvatar

### AvatarDataOutput

```solidity
struct AvatarDataOutput {
  address contractAddress;
  uint256 tokenId;
  uint256 COID;
  uint256 BombUsed;
  uint32 tileCoordinate;
}
```

### OnMapParams

```solidity
struct OnMapParams {
  uint32 tileCoordinate;
  address collectionContract;
  uint256 tokenId;
  uint256 linkedAvatarId;
  uint32 LandId;
  enum IAvatar.DelegateWallet delegateWallet;
  address vault;
}
```

### BombParams

```solidity
struct BombParams {
  uint32 tileCoordinate;
  address collectionContract;
  uint256 tokenId;
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

### getAvatarByAvatarId

```solidity
function getAvatarByAvatarId(uint256 avatarId) external view returns (struct IAvatar.AvatarDataOutput avatarData)
```

get avatar info by avatarId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarData | struct IAvatar.AvatarDataOutput | avatar data format struct AvatarDataOutput |

### getAvatarByNFT

```solidity
function getAvatarByNFT(address collection, uint256 tokenId) external view returns (struct IAvatar.AvatarDataOutput avatarData)
```

get avatar info by nft contractAddress and tokenId

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collection | address | collection contract address |
| tokenId | uint256 | token Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarData | struct IAvatar.AvatarDataOutput | avatar data format struct AvatarDataOutput |

### getAvatarsByNFTs

```solidity
function getAvatarsByNFTs(address[] collections, uint256[] tokenIds) external view returns (struct IAvatar.AvatarDataOutput[] avatarDatas)
```

get avatar infos by nft contractAddresses and tokenIds

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collections | address[] | array of collection contract address |
| tokenIds | uint256[] | array of token Ids |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarDatas | struct IAvatar.AvatarDataOutput[] | avatar datas format struct AvatarDataOutput |

### getAvatarsByCoordinateRange

```solidity
function getAvatarsByCoordinateRange(uint32 startCoordinate, int32 width, int32 height) external view returns (struct IAvatar.AvatarDataOutput[] avatarDatas)
```

get avatar infos by tile sets start by start coordinate and range by width and height

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startCoordinate | uint32 | start tile coordinate |
| width | int32 | range width |
| height | int32 | range height |

### getAvatarsByStartEndCoordinate

```solidity
function getAvatarsByStartEndCoordinate(uint32 startCoordinate, uint32 endCoordinate) external view returns (struct IAvatar.AvatarDataOutput[] avatarDatas)
```

get avatar infos by tile sets start by start coordinate and end by end coordinates

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startCoordinate | uint32 | start tile coordinate |
| endCoordinate | uint32 | end tile coordinate |

### getAvatarsByCoordinates

```solidity
function getAvatarsByCoordinates(uint32[] coordinates) external view returns (struct IAvatar.AvatarDataOutput[] avatarDatas)
```

get avatars by coordinate array

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| coordinates | uint32[] | array of token Ids |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarDatas | struct IAvatar.AvatarDataOutput[] | avatar datas format struct AvatarDataOutput |

### mintAvatar

```solidity
function mintAvatar(address collectionContract, uint256 tokenId, bytes32[] proofs, enum IAvatar.DelegateWallet delegateWallet, address vault) external
```

mint an avatar for a NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collectionContract | address | NFT collection Contract Address |
| tokenId | uint256 | NFT tokenId |
| proofs | bytes32[] | NFT collection whitelist proof |
| delegateWallet | enum IAvatar.DelegateWallet | DelegateWallet enum to specify protocol |
| vault | address | cold wallet address |

### jumpIn

```solidity
function jumpIn(struct IAvatar.OnMapParams params) external
```

an off map avatar jump in to the map

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.OnMapParams | OnMapParams |

### moveTo

```solidity
function moveTo(struct IAvatar.OnMapParams params) external
```

an on map avatar move to a new tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.OnMapParams | OnMapParams |

### bomb

```solidity
function bomb(struct IAvatar.BombParams params) external
```

throw a bomb to a tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.BombParams | BombParams |

