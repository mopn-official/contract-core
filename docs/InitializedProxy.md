# Solidity API

## IGov

### mopnCollectionVaultContract

```solidity
function mopnCollectionVaultContract() external view returns (address)
```

## InitializedProxy

### governance

```solidity
address governance
```

### constructor

```solidity
constructor(address governance_, bytes _initializationCalldata) public
```

### _implementation

```solidity
function _implementation() internal view returns (address)
```

_This is a virtual function that should be overridden so it returns the address to which the fallback function
and {_fallback} should delegate._

