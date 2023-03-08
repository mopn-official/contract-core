# Solidity API

## LandMetaDataRender

### setGovernanceContract

```solidity
function setGovernanceContract(address governanceContract_) public
```

_set the governance contract address
this function also get the Map contract from the governances_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| governanceContract_ | address | Governance Contract Address |

### constructTokenURI

```solidity
function constructTokenURI(uint256 LandId_) public view returns (string)
```

