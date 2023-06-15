# Solidity API

## MopnBatchHelper

### governance

```solidity
contract IGovernance governance
```

### auctionHouse

```solidity
contract IAuctionHouse auctionHouse
```

### avatar

```solidity
contract IAvatar avatar
```

### map

```solidity
contract IMap map
```

### miningData

```solidity
contract IMiningData miningData
```

### constructor

```solidity
constructor(address governanceContract_) public
```

### governanceContract

```solidity
function governanceContract() public view returns (address)
```

### _setGovernanceContract

```solidity
function _setGovernanceContract(address governanceContract_) internal
```

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

### batchMintAvatarMT

```solidity
function batchMintAvatarMT(uint256[] avatarIds) public
```

### redeemRealtimeLandHolderMT

```solidity
function redeemRealtimeLandHolderMT(uint32 LandId, uint256[] avatarIds) public
```

### batchRedeemRealtimeLandHolderMT

```solidity
function batchRedeemRealtimeLandHolderMT(uint32[] LandIds, uint256[][] avatarIds) public
```

batch redeem land holder unclaimed minted mopn token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| LandIds | uint32[] | Land Ids |
| avatarIds | uint256[][] |  |

### redeemAgioTo

```solidity
function redeemAgioTo() public
```

