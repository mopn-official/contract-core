# Solidity API

## Governance

_Governance is all other MOPN contract's owner_

### MTProducePerBlock

```solidity
uint256 MTProducePerBlock
```

### MTProduceReduceInterval

```solidity
uint256 MTProduceReduceInterval
```

### MTProduceStartBlock

```solidity
uint256 MTProduceStartBlock
```

### MTProduceData

```solidity
uint256 MTProduceData
```

PerMTAWMinted * 10 ** 24 + LastPerMTAWMintedCalcBlock * 10 ** 12 + TotalMTAWs

### AvatarMTs

```solidity
mapping(uint256 => uint256) AvatarMTs
```

MT Inbox * 10 ** 52 + Total Minted MT * 10 ** 32 + PerMTAWMinted * 10 ** 12 + TotalMTAWs

### CollectionMTs

```solidity
mapping(uint256 => uint256) CollectionMTs
```

### LandHolderMTs

```solidity
mapping(uint32 => uint256) LandHolderMTs
```

### MTClaimed

```solidity
event MTClaimed(address to, uint256 amount)
```

### constructor

```solidity
constructor(uint256 MTProduceStartBlock_) public
```

### getPerMTAWMinted

```solidity
function getPerMTAWMinted() public view returns (uint256)
```

get settled Per MT Allocation Weight minted mopn token number

### getLastPerMTAWMintedCalcBlock

```solidity
function getLastPerMTAWMintedCalcBlock() public view returns (uint256)
```

get MT last minted settlement block number

### getTotalMTAWs

```solidity
function getTotalMTAWs() public view returns (uint256)
```

get total mopn token allocation weights

### addMTAW

```solidity
function addMTAW(uint256 avatarId, uint256 COID, uint32 LandId, uint256 amount) public
```

add on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| LandId | uint32 | mopn Land Id |
| amount | uint256 | EAW amount |

### subMTAW

```solidity
function subMTAW(uint256 avatarId, uint256 COID, uint32 LandId) public
```

substruct on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| LandId | uint32 | mopn Land Id |

### MTPPBMap

```solidity
uint256[] MTPPBMap
```

### MTPPBZeroTriger

```solidity
uint256 MTPPBZeroTriger
```

### currentMTPPB

```solidity
function currentMTPPB(uint256 reduceTimes) public view returns (uint256 MTPPB)
```

get current mopn token produce per block

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| reduceTimes | uint256 | mopn token produce reduce times |

### settlePerMTAWMinted

```solidity
function settlePerMTAWMinted() public
```

settle per mopn token allocation weight mint mopn token

### calcPerMTAWMinted

```solidity
function calcPerMTAWMinted() public view returns (uint256)
```

### getAvatarSettledInboxMT

```solidity
function getAvatarSettledInboxMT(uint256 avatarId) public view returns (uint256)
```

get avatar settled unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### getAvatarTotalMinted

```solidity
function getAvatarTotalMinted(uint256 avatarId) public view returns (uint256)
```

### getAvatarPerMTAWMinted

```solidity
function getAvatarPerMTAWMinted(uint256 avatarId) public view returns (uint256)
```

get avatar settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### getAvatarMTAW

```solidity
function getAvatarMTAW(uint256 avatarId) public view returns (uint256)
```

get avatar on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### mintAvatarMT

```solidity
function mintAvatarMT(uint256 avatarId) public
```

mint avatar mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### getAvatarInboxMT

```solidity
function getAvatarInboxMT(uint256 avatarId) public view returns (uint256 inbox)
```

get avatar realtime unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

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

### batchRedeemAvatarInboxMT

```solidity
function batchRedeemAvatarInboxMT(uint256[] avatarIds, enum IAvatar.DelegateWallet[] delegateWallets, address[] vaults) public
```

batch redeem avatar unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarIds | uint256[] | avatar Ids |
| delegateWallets | enum IAvatar.DelegateWallet[] | Delegate coldwallet to specify hotwallet protocol |
| vaults | address[] | cold wallet address |

### getCollectionSettledInboxMT

```solidity
function getCollectionSettledInboxMT(uint256 COID) public view returns (uint256)
```

get collection settled minted unclaimed mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### getCollectionTotalMinted

```solidity
function getCollectionTotalMinted(uint256 COID) public view returns (uint256)
```

### getCollectionPerMTAWMinted

```solidity
function getCollectionPerMTAWMinted(uint256 COID) public view returns (uint256)
```

get collection settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### getCollectionMTAW

```solidity
function getCollectionMTAW(uint256 COID) public view returns (uint256)
```

get collection on map mining mopn token allocation weight

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

### getCollectionInboxMT

```solidity
function getCollectionInboxMT(uint256 COID) public view returns (uint256 inbox)
```

get collection realtime unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### redeemCollectionInboxMT

```solidity
function redeemCollectionInboxMT(uint256 avatarId, uint256 COID) public
```

redeem 1/collectionOnMapNFTNumber of collection unclaimed minted mopn token to a avatar
only avatar contract can calls

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |

### getLandHolderSettledInboxMT

```solidity
function getLandHolderSettledInboxMT(uint32 LandId) public view returns (uint256)
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

### getLandHolderPerMTAWMinted

```solidity
function getLandHolderPerMTAWMinted(uint32 LandId) public view returns (uint256)
```

get Land holder settled per mopn token allocation weight minted mopn token number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### getLandHolderMTAW

```solidity
function getLandHolderMTAW(uint32 LandId) public view returns (uint256)
```

get Land holder on map mining mopn token allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### mintLandHolderMT

```solidity
function mintLandHolderMT(uint32 LandId) public
```

mint Land holder mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### getLandHolderInboxMT

```solidity
function getLandHolderInboxMT(uint32 LandId) public view returns (uint256 inbox)
```

get Land holder realtime unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### redeemLandHolderInboxMT

```solidity
function redeemLandHolderInboxMT(uint32 LandId) public
```

redeem Land holder unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### getLandHolderRedeemed

```solidity
function getLandHolderRedeemed(uint32 LandId) public view returns (uint256)
```

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

Collection address => COID * 1000000 + on map nft number

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

### getCollectionInfo

```solidity
function getCollectionInfo(uint256 COID) public view returns (address collectionAddress, uint256 onMapNum, uint256 avatarNum, uint256 totalMTAWs, uint256 totalMinted)
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
function burnBomb(address from, uint256 amount, uint256 avatarId, uint256 COID, uint32 LandId) public
```

### mintLand

```solidity
function mintLand(address to) public
```

### redeemAgio

```solidity
function redeemAgio() public
```

### _addMTAW

```solidity
function _addMTAW(uint256 avatarId, uint256 COID, uint32 LandId, uint256 amount) internal
```

### _subMTAW

```solidity
function _subMTAW(uint256 avatarId, uint256 COID, uint32 LandId) internal
```

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

