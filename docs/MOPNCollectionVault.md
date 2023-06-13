# Solidity API

## MOPNCollectionVault

### COID

```solidity
uint256 COID
```

### isInitialized

```solidity
bool isInitialized
```

### governance

```solidity
contract IGovernance governance
```

### NFTOfferData

```solidity
uint256 NFTOfferData
```

NFTOfferData
Bits Layouts:
 - [0..0] OfferStatus 0 offering 1 auctioning
 - [1..32] Auction Start Timestamp
 - [33..96] Offer Accept Price
 - [97..255] Auction tokenId

### constructor

```solidity
constructor(address governance_) public
```

### getOfferStatus

```solidity
function getOfferStatus() public view returns (uint256)
```

### getAuctionStartTimestamp

```solidity
function getAuctionStartTimestamp() public view returns (uint256)
```

### getOfferAcceptPrice

```solidity
function getOfferAcceptPrice() public view returns (uint256)
```

### getAuctionTokenId

```solidity
function getAuctionTokenId() public view returns (uint256)
```

### initialize

```solidity
function initialize(uint256 COID_) public
```

### MT2VAmount

```solidity
function MT2VAmount(uint256 MTAmount) public view returns (uint256 VAmount)
```

### V2MTAmount

```solidity
function V2MTAmount(uint256 VAmount) public view returns (uint256 MTAmount)
```

### withdraw

```solidity
function withdraw(uint256 amount) public
```

### getNFTOfferPrice

```solidity
function getNFTOfferPrice() public view returns (uint256)
```

### MTBalance

```solidity
function MTBalance() public view returns (uint256 balance)
```

### acceptNFTOffer

```solidity
function acceptNFTOffer(uint256 tokenId) public
```

### getAuctionCurrentPrice

```solidity
function getAuctionCurrentPrice() public view returns (uint256)
```

get the current auction price for land

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | price current auction price |

### getAuctionPrice

```solidity
function getAuctionPrice(uint256 reduceTimes) public view returns (uint256)
```

### onERC20Received

```solidity
function onERC20Received(address, address from, uint256 value, bytes data) public returns (bytes4)
```

