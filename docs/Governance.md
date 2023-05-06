# Solidity API

## Governance

_Governance is all other MOPN contract's owner_

### MTClaimed

```solidity
event MTClaimed(uint256 avatarId, uint256 COID, address to, uint256 amount)
```

### MTClaimedCollectionVault

```solidity
event MTClaimedCollectionVault(uint256 avatarId, uint256 COID, address to, uint256 amount)
```

### redeemAvatarInboxMT

```solidity
function redeemAvatarInboxMT(uint256 avatarId, enum IAvatar.DelegateWallet delegateWallet, address vault) public
```

redeem avatar unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| delegateWallet | enum IAvatar.DelegateWallet | Delegate coldwallet to specify hotwallet protocol |
| vault | address | cold wallet address |

### redeemCollectionInboxMT

```solidity
function redeemCollectionInboxMT(address to, uint256 avatarId, uint256 COID) public
```

redeem collection unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address |  |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |

### redeemLandHolderInboxMT

```solidity
function redeemLandHolderInboxMT(uint32 LandId) public
```

redeem Land holder unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### whiteListRequire

```solidity
bool whiteListRequire
```

### setWhiteListRequire

```solidity
function setWhiteListRequire(bool whiteListRequire_) public
```

### whiteListRoot

```solidity
bytes32 whiteListRoot
```

### isInWhiteList

```solidity
function isInWhiteList(address collectionContract, bytes32[] proofs) public view returns (bool)
```

check if this collection is in white list

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collectionContract | address | collection contract address |
| proofs | bytes32[] | collection whitelist proofs |

### updateWhiteList

```solidity
function updateWhiteList(bytes32 whiteListRoot_) public
```

update whitelist root

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| whiteListRoot_ | bytes32 | white list merkle tree root |

### COIDCounter

```solidity
uint256 COIDCounter
```

### COIDMap

```solidity
mapping(uint256 => address) COIDMap
```

### collectionMap

```solidity
mapping(address => uint256) collectionMap
```

record the collection's COID and number of collection nfts which is standing on the map with last 6 digit

Collection address => uint64 COID + uint64 minted avatar num + uint64 on map nft number

### getCollectionContract

```solidity
function getCollectionContract(uint256 COID) public view returns (address)
```

use collection Id to get collection contract address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | contractAddress collection contract address |

### getCollectionCOID

```solidity
function getCollectionCOID(address collectionContract) public view returns (uint256)
```

use collection contract address to get collection Id

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collectionContract | address | collection contract address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | COID collection Id |

### getCollectionsCOIDs

```solidity
function getCollectionsCOIDs(address[] collectionContracts) public view returns (uint256[] COIDs)
```

batch call for {getCollectionCOID}

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collectionContracts | address[] | multi collection contracts |

### generateCOID

```solidity
function generateCOID(address collectionContract, bytes32[] proofs) public returns (uint256 COID)
```

Generate a collection id for new collection

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| collectionContract | address | collection contract adddress |
| proofs | bytes32[] | collection whitelist proofs |

### getCollectionOnMapNum

```solidity
function getCollectionOnMapNum(uint256 COID) public view returns (uint256)
```

get NFT collection On map avatar number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### addCollectionOnMapNum

```solidity
function addCollectionOnMapNum(uint256 COID) public
```

### subCollectionOnMapNum

```solidity
function subCollectionOnMapNum(uint256 COID) public
```

### getCollectionAvatarNum

```solidity
function getCollectionAvatarNum(uint256 COID) public view returns (uint256)
```

get NFT collection minted avatar number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### addCollectionAvatarNum

```solidity
function addCollectionAvatarNum(uint256 COID) public
```

### auctionHouseContract

```solidity
address auctionHouseContract
```

### avatarContract

```solidity
address avatarContract
```

### bombContract

```solidity
address bombContract
```

### mtContract

```solidity
address mtContract
```

### mapContract

```solidity
address mapContract
```

### landContract

```solidity
address landContract
```

### updateMOPNContracts

```solidity
function updateMOPNContracts(address auctionHouseContract_, address avatarContract_, address bombContract_, address mtContract_, address mapContract_, address landContract_) public
```

### mintBomb

```solidity
function mintBomb(address to, uint256 amount) public
```

### burnBomb

```solidity
function burnBomb(address from, uint256 amount) public
```

### redeemAgio

```solidity
function redeemAgio() public
```

### giveupOwnership

```solidity
function giveupOwnership() public
```

todo remove before prod

### onlyAuctionHouse

```solidity
modifier onlyAuctionHouse()
```

### onlyAvatar

```solidity
modifier onlyAvatar()
```

### onlyMap

```solidity
modifier onlyMap()
```

