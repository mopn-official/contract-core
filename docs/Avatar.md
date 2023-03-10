# Solidity API

## LandIdTilesNotOpen

```solidity
error LandIdTilesNotOpen()
```

## linkAvatarError

```solidity
error linkAvatarError()
```

## WarmInterface

### ownerOf

```solidity
function ownerOf(address contractAddress, uint256 tokenId) external view returns (address)
```

## DelegateCashInterface

### checkDelegateForToken

```solidity
function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool)
```

## Avatar

_This Contract's owner must transfer to Governance Contract once it's deployed_

### AvatarData

```solidity
struct AvatarData {
  uint256 tokenId;
  uint256 setData;
}
```

### AvatarMint

```solidity
event AvatarMint(uint256 avatarId, uint256 COID)
```

### AvatarJumpIn

```solidity
event AvatarJumpIn(uint256 avatarId, uint256 COID, uint32 LandId, uint32 tileCoordinate)
```

This event emit when an avatar jump into the map

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| LandId | uint32 | MOPN Land Id |
| tileCoordinate | uint32 | tile coordinate |

### AvatarMove

```solidity
event AvatarMove(uint256 avatarId, uint256 COID, uint32 LandId, uint32 fromCoordinate, uint32 toCoordinate)
```

This event emit when an avatar move on map

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| LandId | uint32 | MOPN Land Id |
| fromCoordinate | uint32 | tile coordinate |
| toCoordinate | uint32 | tile coordinate |

### BombUse

```solidity
event BombUse(uint256 avatarId, uint32 tileCoordinate, uint256[] victims, uint32[] victimsCoordinates)
```

BombUse Event emit when a Bomb is used at a coordinate by an avatar

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatarId that has indexed |
| tileCoordinate | uint32 | the tileCoordinate |
| victims | uint256[] | thje victims that bombed out of the map |
| victimsCoordinates | uint32[] |  |

### avatarNoumenon

```solidity
mapping(uint256 => struct Avatar.AvatarData) avatarNoumenon
```

avatar storage map
        avatarId => AvatarData

### tokenMap

```solidity
mapping(address => mapping(uint256 => uint256)) tokenMap
```

### currentAvatarId

```solidity
uint256 currentAvatarId
```

### setGovernanceContract

```solidity
function setGovernanceContract(address governanceContract_) public
```

_set the governance contract address
this function also get the Map contract from the governances_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| governanceContract_ | address | Governance Contract Address |

### getAvatarByAvatarId

```solidity
function getAvatarByAvatarId(uint256 avatarId) public view returns (struct IAvatar.AvatarDataOutput avatarData)
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
function getAvatarByNFT(address collection, uint256 tokenId) public view returns (struct IAvatar.AvatarDataOutput avatarData)
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
function getAvatarsByNFTs(address[] collections, uint256[] tokenIds) public view returns (struct IAvatar.AvatarDataOutput[] avatarDatas)
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
function getAvatarsByCoordinateRange(uint32 startCoordinate, int32 width, int32 height) public view returns (struct IAvatar.AvatarDataOutput[] avatarDatas)
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
function getAvatarsByStartEndCoordinate(uint32 startCoordinate, uint32 endCoordinate) public view returns (struct IAvatar.AvatarDataOutput[] avatarDatas)
```

get avatar infos by tile sets start by start coordinate and end by end coordinates

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startCoordinate | uint32 | start tile coordinate |
| endCoordinate | uint32 | end tile coordinate |

### getAvatarsByCoordinates

```solidity
function getAvatarsByCoordinates(uint32[] coordinates) public view returns (struct IAvatar.AvatarDataOutput[] avatarDatas)
```

get avatars by coordinate array

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| coordinates | uint32[] | array of coordinates |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarDatas | struct IAvatar.AvatarDataOutput[] | avatar datas format struct AvatarDataOutput |

### getAvatarCOID

```solidity
function getAvatarCOID(uint256 avatarId) public view returns (uint256)
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

### getAvatarBombUsed

```solidity
function getAvatarBombUsed(uint256 avatarId) public view returns (uint256)
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
function getAvatarCoordinate(uint256 avatarId) public view returns (uint32)
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

### WARM_CONTRACT_ADDRESS

```solidity
address WARM_CONTRACT_ADDRESS
```

### DelegateCash_CONTRACT_ADDRESS

```solidity
address DelegateCash_CONTRACT_ADDRESS
```

### ownerOf

```solidity
function ownerOf(address collectionContract, uint256 tokenId, enum IAvatar.DelegateWallet delegateWallet, address vault) public view returns (address owner)
```

get the original owner of a NFT
MOPN Avatar support hot wallet protocol https://delegate.cash/ and https://warm.xyz/ to verify your NFTs

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collectionContract | address | NFT collection Contract Address |
| tokenId | uint256 | NFT tokenId |
| delegateWallet | enum IAvatar.DelegateWallet | DelegateWallet enum to specify protocol |
| vault | address | cold wallet address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | nft owner or nft delegate hot wallet |

### ownerOf

```solidity
function ownerOf(uint256 avatarId, enum IAvatar.DelegateWallet delegateWallet, address vault) public view returns (address)
```

get the original owner of a avatar linked nft

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| delegateWallet | enum IAvatar.DelegateWallet | DelegateWallet enum to specify protocol |
| vault | address | cold wallet address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | owner nft owner or nft delegate hot wallet |

### mintAvatar

```solidity
function mintAvatar(address collectionContract, uint256 tokenId, bytes32[] proofs, enum IAvatar.DelegateWallet delegateWallet, address vault) public
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
function jumpIn(struct IAvatar.OnMapParams params) public
```

an off map avatar jump in to the map

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.OnMapParams | OnMapParams |

### moveTo

```solidity
function moveTo(struct IAvatar.OnMapParams params) public
```

an on map avatar move to a new tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.OnMapParams | OnMapParams |

### bomb

```solidity
function bomb(struct IAvatar.BombParams params) public
```

throw a bomb to a tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.BombParams | OnMapParams |

### addAvatarBombUsed

```solidity
function addAvatarBombUsed(uint256 avatarId) internal
```

### setAvatarCoordinate

```solidity
function setAvatarCoordinate(uint256 avatarId, uint32 tileCoordinate) internal
```

### linkCheck

```solidity
function linkCheck(uint256 avatarId, uint256 linkedAvatarId, uint32 tileCoordinate) internal
```

### tileCheck

```solidity
modifier tileCheck(uint32 tileCoordinate)
```

### ownerCheck

```solidity
modifier ownerCheck(address collectionContract, uint256 tokenId, enum IAvatar.DelegateWallet delegateWallet, address vault)
```

### onlyMap

```solidity
modifier onlyMap()
```

