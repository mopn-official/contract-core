# Solidity API

## LandMetaDataRender

### governance

```solidity
contract IGovernance governance
```

### constructor

```solidity
constructor(address governance_) public
```

_set the governance contract address
this function also get the Map contract from the governances_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| governance_ | address | Governance Contract Address |

### constructTokenURI

```solidity
function constructTokenURI(uint256 LandId_) public view returns (string)
```

