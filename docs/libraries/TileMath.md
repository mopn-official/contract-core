# Solidity API

## TileMath

### TileCoordinateError

```solidity
error TileCoordinateError()
```

### check

```solidity
function check(uint32 tileCoordinate) public pure
```

### PassRingNum

```solidity
function PassRingNum(uint32 PassId) public pure returns (uint32 n)
```

### PassRingPos

```solidity
function PassRingPos(uint32 PassId) public pure returns (uint32)
```

### PassRingStartCenterTile

```solidity
function PassRingStartCenterTile(uint32 PassIdRingNum_) public pure returns (uint32)
```

### PassCenterTile

```solidity
function PassCenterTile(uint32 PassId) public pure returns (uint32 tileCoordinate)
```

### PassTileRange

```solidity
function PassTileRange(uint32 tileCoordinate) public pure returns (uint32[], uint32[])
```

### getPassTilesEAW

```solidity
function getPassTilesEAW(uint32 PassId) public pure returns (uint256[])
```

### getTileEAW

```solidity
function getTileEAW(uint32 tileCoordinate) public pure returns (uint256)
```

### coordinateIntToArr

```solidity
function coordinateIntToArr(uint32 tileCoordinate) public pure returns (uint32[3] coordinateArr)
```

### spiralRingTiles

```solidity
function spiralRingTiles(uint32 tileCoordinate, uint256 radius) public pure returns (uint32[])
```

### ringTiles

```solidity
function ringTiles(uint32 tileCoordinate, uint256 radius) public pure returns (uint32[])
```

### tileSpheres

```solidity
function tileSpheres(uint32 tileCoordinate) public pure returns (uint32[])
```

### direction

```solidity
function direction(uint256 direction_) public pure returns (int32)
```

### neighbor

```solidity
function neighbor(uint32 tileCoordinate, uint256 direction_) public pure returns (uint32)
```

### distance

```solidity
function distance(uint32 a, uint32 b) public pure returns (uint32 d)
```

