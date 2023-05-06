# Solidity API

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
event AvatarMint(uint256 avatarId, uint256 COID, address collectionContract, uint256 tokenId)
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

### governanceContract

```solidity
address governanceContract
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

### getNFTAvatarId

```solidity
function getNFTAvatarId(address contractAddress, uint256 tokenId) public view returns (uint256)
```

### getAvatarTokenId

```solidity
function getAvatarTokenId(uint256 avatarId) public view returns (uint256)
```

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

### addAvatarBombUsed

```solidity
function addAvatarBombUsed(uint256 avatarId) internal
```

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

### setAvatarCoordinate

```solidity
function setAvatarCoordinate(uint256 avatarId, uint32 tileCoordinate) internal
```

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
function mintAvatar(struct IAvatar.NFTParams params) internal returns (uint256)
```

mint an avatar for a NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.NFTParams | NFTParams |

### moveTo

```solidity
function moveTo(struct IAvatar.NFTParams params, uint32 tileCoordinate, uint256 linkedAvatarId, uint32 LandId) public
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
function bomb(struct IAvatar.NFTParams params, uint32 tileCoordinate) public
```

throw a bomb to a tile

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IAvatar.NFTParams | NFTParams |
| tileCoordinate | uint32 |  |

### linkCheck

```solidity
function linkCheck(uint256 avatarId, uint256 linkedAvatarId, uint32 tileCoordinate) internal view
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

