# Solidity API

## Governance

_Governance is all other MOPN contract's owner_

### EnergyProducePerBlock

```solidity
uint256 EnergyProducePerBlock
```

### EnergyProduceReduceInterval

```solidity
uint256 EnergyProduceReduceInterval
```

### EnergyProduceStartBlock

```solidity
uint256 EnergyProduceStartBlock
```

### EnergyProduceData

```solidity
uint256 EnergyProduceData
```

PerEAWMintedEnergy * 10 ** 24 + EnergyLastMintedBlock * 10 ** 12 + TotalEAWs

### AvatarEnergys

```solidity
mapping(uint256 => uint256) AvatarEnergys
```

### CollectionEnergys

```solidity
mapping(uint256 => uint256) CollectionEnergys
```

### LandHolderEnergys

```solidity
mapping(uint32 => uint256) LandHolderEnergys
```

### constructor

```solidity
constructor(uint256 EnergyProduceStartBlock_, bool whiteListRequire_) public
```

### getPerEAWMinted

```solidity
function getPerEAWMinted() public view returns (uint256)
```

get settled Per Energy Allocation Weight minted energy number

### getEnergyLastMintedBlock

```solidity
function getEnergyLastMintedBlock() public view returns (uint256)
```

get Energy last minted settlement block number

### getTotalEAWs

```solidity
function getTotalEAWs() public view returns (uint256)
```

get total energy allocation weights

### addEAW

```solidity
function addEAW(uint256 avatarId, uint256 COID, uint32 LandId, uint256 amount) public
```

add on map mining energy allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| LandId | uint32 | mopn Land Id |
| amount | uint256 | EAW amount |

### subEAW

```solidity
function subEAW(uint256 avatarId, uint256 COID, uint32 LandId) public
```

substruct on map mining energy allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |
| LandId | uint32 | mopn Land Id |

### EPPBMap

```solidity
uint256[] EPPBMap
```

### EPPBZeroTriger

```solidity
uint256 EPPBZeroTriger
```

### currentEPPB

```solidity
function currentEPPB(uint256 reduceTimes) public view returns (uint256 EPPB)
```

get current energy produce per block

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| reduceTimes | uint256 | energy produce reduce times |

### settlePerEAWEnergy

```solidity
function settlePerEAWEnergy() public
```

settle per energy allocation weight mint energy

### calcPerEAWEnergy

```solidity
function calcPerEAWEnergy() public view returns (uint256)
```

### getAvatarSettledInboxEnergy

```solidity
function getAvatarSettledInboxEnergy(uint256 avatarId) public view returns (uint256)
```

get avatar settled unclaimed minted energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### getAvatarTotalMinted

```solidity
function getAvatarTotalMinted(uint256 avatarId) public view returns (uint256)
```

### getAvatarPerEAWMinted

```solidity
function getAvatarPerEAWMinted(uint256 avatarId) public view returns (uint256)
```

get avatar settled per energy allocation weight minted energy number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### getAvatarEAW

```solidity
function getAvatarEAW(uint256 avatarId) public view returns (uint256)
```

get avatar on map mining energy allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### mintAvatarEnergy

```solidity
function mintAvatarEnergy(uint256 avatarId) public
```

mint avatar energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### getAvatarInboxEnergy

```solidity
function getAvatarInboxEnergy(uint256 avatarId) public view returns (uint256 inbox)
```

get avatar realtime unclaimed minted energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |

### redeemAvatarInboxEnergy

```solidity
function redeemAvatarInboxEnergy(uint256 avatarId, enum IAvatar.DelegateWallet delegateWallet, address vault) public
```

redeem avatar unclaimed minted energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| delegateWallet | enum IAvatar.DelegateWallet | Delegate coldwallet to specify hotwallet protocol |
| vault | address | cold wallet address |

### getCollectionSettledInboxEnergy

```solidity
function getCollectionSettledInboxEnergy(uint256 COID) public view returns (uint256)
```

get collection settled minted unclaimed energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### getCollectionTotalMinted

```solidity
function getCollectionTotalMinted(uint256 COID) public view returns (uint256)
```

### getCollectionPerEAWMinted

```solidity
function getCollectionPerEAWMinted(uint256 COID) public view returns (uint256)
```

get collection settled per energy allocation weight minted energy number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### getCollectionEAW

```solidity
function getCollectionEAW(uint256 COID) public view returns (uint256)
```

get collection on map mining energy allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### mintCollectionEnergy

```solidity
function mintCollectionEnergy(uint256 COID) public
```

mint collection energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### getCollectionInboxEnergy

```solidity
function getCollectionInboxEnergy(uint256 COID) public view returns (uint256 inbox)
```

get collection realtime unclaimed minted energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| COID | uint256 | collection Id |

### redeemCollectionInboxEnergy

```solidity
function redeemCollectionInboxEnergy(uint256 avatarId, uint256 COID) public
```

redeem 1/collectionOnMapNFTNumber of collection unclaimed minted energy to a avatar
only avatar contract can calls

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| COID | uint256 | collection Id |

### getLandHolderSettledInboxEnergy

```solidity
function getLandHolderSettledInboxEnergy(uint32 LandId) public view returns (uint256)
```

get Land holder settled minted unclaimed energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### getLandHolderTotalMinted

```solidity
function getLandHolderTotalMinted(uint32 LandId) public view returns (uint256)
```

### getLandHolderPerEAWMinted

```solidity
function getLandHolderPerEAWMinted(uint32 LandId) public view returns (uint256)
```

get Land holder settled per energy allocation weight minted energy number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### getLandHolderEAW

```solidity
function getLandHolderEAW(uint32 LandId) public view returns (uint256)
```

get Land holder on map mining energy allocation weight

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### mintLandHolderEnergy

```solidity
function mintLandHolderEnergy(uint32 LandId) public
```

mint Land holder energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### getLandHolderInboxEnergy

```solidity
function getLandHolderInboxEnergy(uint32 LandId) public view returns (uint256 inbox)
```

get Land holder realtime unclaimed minted energy

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandId | uint32 | MOPN Land Id |

### redeemLandHolderInboxEnergy

```solidity
function redeemLandHolderInboxEnergy(uint32 LandId) public
```

redeem Land holder unclaimed minted energy

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
function getCollectionInfo(uint256 COID) public view returns (address collectionAddress, uint256 onMapNum, uint256 avatarNum, uint256 totalEAWs, uint256 totalMinted)
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

### energyContract

```solidity
address energyContract
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
function updateMOPNContracts(address auctionHouseContract_, address avatarContract_, address bombContract_, address energyContract_, address mapContract_, address landContract_) public
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

### _addEAW

```solidity
function _addEAW(uint256 avatarId, uint256 COID, uint32 LandId, uint256 amount) internal
```

### _subEAW

```solidity
function _subEAW(uint256 avatarId, uint256 COID, uint32 LandId) internal
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

