# Solidity API

## NFTMetaData

### constructTokenURI

```solidity
function constructTokenURI(uint32 LandId, struct NFTSVG.tileData[] tileDatas, uint256 MTMinted) public pure returns (string)
```

### constructAttributes

```solidity
function constructAttributes(uint32 LandId, uint32 blockCoordinate, uint32 ringNum, uint32 totalNFTPoint, uint256 MTMinted) public pure returns (bytes)
```

### constructTokenImage

```solidity
function constructTokenImage(uint32 LandId, string coordinateStr, struct NFTSVG.tileData[] tileDatas) public pure returns (string)
```

### getIntAttributesRangeBytes

```solidity
function getIntAttributesRangeBytes(uint32 blockCoordinate) public pure returns (bytes attributesBytes)
```

### getIntAttributesArray

```solidity
function getIntAttributesArray(string trait_type, uint32[] ary) public pure returns (bytes attributesBytes)
```

### landBgColor

```solidity
function landBgColor(uint32 landId) public pure returns (bytes)
```

### _int2str

```solidity
function _int2str(uint32 n) internal pure returns (string)
```

