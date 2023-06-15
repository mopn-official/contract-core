# Solidity API

## MOPNTESTNFT

### MAX_SUPPLY

```solidity
uint256 MAX_SUPPLY
```

### ADDRESS_MINT_LIMIT

```solidity
uint256 ADDRESS_MINT_LIMIT
```

### constructor

```solidity
constructor(string name, string symbol, string baseURI_) public
```

### safeMint

```solidity
function safeMint(uint256 quantity) public
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
by default, it can be overridden in child contracts._

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view returns (string)
```

_Returns the Uniform Resource Identifier (URI) for `tokenId` token._

