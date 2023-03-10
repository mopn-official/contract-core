# Solidity API

## NFTSVG

### coordinate

```solidity
struct coordinate {
  uint32 x;
  uint32 xdecimal;
  uint32 y;
}
```

### tileData

```solidity
struct tileData {
  uint256 color;
  uint256 tileMTAW;
}
```

### getBlock

```solidity
function getBlock(struct NFTSVG.coordinate co, uint256 blockLevel, uint256 fillcolor) public pure returns (string svg)
```

### getLevelItem

```solidity
function getLevelItem(uint256 level, uint32 x, uint32 y) public pure returns (string)
```

### getImage

```solidity
function getImage(string defs, string background, string blocks) public pure returns (string)
```

### generateDefs

```solidity
function generateDefs(bytes ringbgcolor) public pure returns (string svg)
```

### generateBackground

```solidity
function generateBackground(uint32 id, string coordinateStr) public pure returns (string svg)
```

### generateBlocks

```solidity
function generateBlocks(struct NFTSVG.tileData[] tileDatas) public pure returns (string svg)
```

### COIDToColor

```solidity
function COIDToColor(uint256 COID) public pure returns (string)
```

