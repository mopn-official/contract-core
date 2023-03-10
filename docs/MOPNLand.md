# Solidity API

## MOPNLand

### constructor

```solidity
constructor() public
```

### auctionMint

```solidity
function auctionMint(address to, uint256 amount) public
```

### nextTokenId

```solidity
function nextTokenId() public view returns (uint256)
```

### metaDataRenderAddress

```solidity
address metaDataRenderAddress
```

### setMetaDataRender

```solidity
function setMetaDataRender(address metaDataRenderAddress_) public
```

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view returns (string tokenuri)
```

_See {IERC721Metadata-tokenURI}._

