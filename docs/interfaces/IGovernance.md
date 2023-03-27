# Solidity API

## IGovernance

### DelegateWallet

```solidity
enum DelegateWallet {
  None,
  DelegateCash,
  Warm
}
```

### redeemAvatarInboxMT

```solidity
function redeemAvatarInboxMT(uint256 avatarId, enum IGovernance.DelegateWallet delegateWallet, address vault) external
```

redeem avatar unclaimed minted MOPN Tokens

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| avatarId | uint256 | avatar Id |
| delegateWallet | enum IGovernance.DelegateWallet | Delegate coldwallet to specify hotwallet protocol |
| vault | address | cold wallet address |

### redeemLandHolderInboxMT

```solidity
function redeemLandHolderInboxMT(uint32 LandId) external
```

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

### mintBomb

```solidity
function mintBomb(address to, uint256 amount) external
```

### burnBomb

```solidity
function burnBomb(address from, uint256 amount) external
```

### redeemAgio

```solidity
function redeemAgio() external
```

### mintLand

```solidity
function mintLand(address to) external
```

### avatarContract

```solidity
function avatarContract() external view returns (address)
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

