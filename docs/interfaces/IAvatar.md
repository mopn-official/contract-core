# Solidity API

## IAvatar

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

### getAvatarCOID

```solidity
function getAvatarCOID(uint256 avatarId) external view returns (uint256)
```

