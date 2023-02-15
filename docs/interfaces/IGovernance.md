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

### addEAW

```solidity
function addEAW(uint256 avatarId, uint256 COID, uint32 PassId, uint256 amount) external
```

### subEAW

```solidity
function subEAW(uint256 avatarId, uint256 COID, uint32 PassId) external
```

### mintBomb

```solidity
function mintBomb(address to, uint256 amount) external
```

### burnBomb

```solidity
function burnBomb(address from, uint256 amount, uint256 avatarId, uint256 COID, uint32 PassId) external
```

### redeemCollectionInboxEnergy

```solidity
function redeemCollectionInboxEnergy(uint256 avatarId, uint256 COID) external
```

### avatarContract

```solidity
function avatarContract() external view returns (address)
```

### bombContract

```solidity
function bombContract() external view returns (address)
```

### energyContract

```solidity
function energyContract() external view returns (address)
```

### mapContract

```solidity
function mapContract() external view returns (address)
```

### passContract

```solidity
function passContract() external view returns (address)
```

