# Solidity API

## IGovernance

### getCollectionContract

```solidity
function getCollectionContract(uint256 COID) external view returns (address)
```

### getCollectionCOID

```solidity
function getCollectionCOID(address collectionContract) external view returns (uint256)
```

### getCollectionsCOIDs

```solidity
function getCollectionsCOIDs(address[] collectionContracts) external view returns (uint256[] COIDs)
```

### generateCOID

```solidity
function generateCOID(address collectionContract, bytes32[] proofs) external returns (uint256)
```

### isInWhiteList

```solidity
function isInWhiteList(address collectionContract, bytes32[] proofs) external view returns (bool)
```

### updateWhiteList

```solidity
function updateWhiteList(bytes32 whiteListRoot_) external
```

### addCollectionOnMapNum

```solidity
function addCollectionOnMapNum(uint256 COID) external
```

### subCollectionOnMapNum

```solidity
function subCollectionOnMapNum(uint256 COID) external
```

### getCollectionOnMapNum

```solidity
function getCollectionOnMapNum(uint256 COID) external view returns (uint256)
```

### addCollectionAvatarNum

```solidity
function addCollectionAvatarNum(uint256 COID) external
```

### getCollectionAvatarNum

```solidity
function getCollectionAvatarNum(uint256 COID) external view returns (uint256)
```

### getCollectionMintedMT

```solidity
function getCollectionMintedMT(uint256 COID) external view returns (uint256)
```

### addCollectionMintedMT

```solidity
function addCollectionMintedMT(uint256 COID, uint256 amount) external
```

### clearCollectionMintedMT

```solidity
function clearCollectionMintedMT(uint256 COID) external
```

### getCollectionVault

```solidity
function getCollectionVault(uint256 COID) external view returns (address)
```

### mintMT

```solidity
function mintMT(address to, uint256 amount) external
```

### mintBomb

```solidity
function mintBomb(address to, uint256 amount) external
```

### burnBomb

```solidity
function burnBomb(address from, uint256 amount) external
```

### auctionHouseContract

```solidity
function auctionHouseContract() external view returns (address)
```

### mopnContract

```solidity
function mopnContract() external view returns (address)
```

### bombContract

```solidity
function bombContract() external view returns (address)
```

### mtContract

```solidity
function mtContract() external view returns (address)
```

### mapContract

```solidity
function mapContract() external view returns (address)
```

### landContract

```solidity
function landContract() external view returns (address)
```

### mopnDataContract

```solidity
function mopnDataContract() external view returns (address)
```
