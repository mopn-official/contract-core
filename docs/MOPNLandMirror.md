# Solidity API

## MOPNLandMirror

### MAX_SUPPLY

```solidity
uint256 MAX_SUPPLY
```

### constructor

```solidity
constructor() public
```

### claim

```solidity
function claim(address to, uint256 tokenId) public
```

### auctionMint

```solidity
function auctionMint(address to, uint256 amount) public view
```

### nextTokenId

```solidity
function nextTokenId() public view returns (uint256)
```

### metadataRenderAddress

```solidity
address metadataRenderAddress
```

### auctionAddress

```solidity
address auctionAddress
```

### setRender

```solidity
function setRender(address metaDataRenderAddress_) public
```

### setAuction

```solidity
function setAuction(address auctionAddress_) public
```

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view returns (string tokenuri)
```

_See {IERC721Metadata-tokenURI}._

