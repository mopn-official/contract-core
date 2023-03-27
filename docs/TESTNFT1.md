# Solidity API

## TESTNFT1

### constructor

```solidity
constructor() public
```

### safeMint

```solidity
function safeMint(address to, uint256 amount) public
```

### nextTokenId1

```solidity
function nextTokenId1() public view returns (uint256)
```

### baseURI

```solidity
string baseURI
```

### setBaseURI

```solidity
function setBaseURI(string baseURI_) public
```

### _baseURI

```solidity
function _baseURI() internal view returns (string)
```

_Base URI for computing {tokenURI}. If set, the resulting URI for each
token will be the concatenation of the `baseURI` and the `tokenId`. Empty
by default, can be overridden in child contracts._

