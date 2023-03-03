# Solidity API

## TileMath

### XYCoordinate

```solidity
struct XYCoordinate {
  int32 x;
  int32 y;
}
```

### TileCoordinateError

```solidity
error TileCoordinateError()
```

### check

```solidity
function check(uint32 tileCoordinate) public pure
```

### LandRingNum

```solidity
function LandRingNum(uint32 LandId) public pure returns (uint32 n)
```

### LandRingPos

```solidity
function LandRingPos(uint32 LandId) public pure returns (uint32)
```

### LandRingStartCenterTile

```solidity
function LandRingStartCenterTile(uint32 LandIdRingNum_) public pure returns (uint32)
```

### LandCenterTile

```solidity
function LandCenterTile(uint32 LandId) public pure returns (uint32 tileCoordinate)
```

### LandTileRange

```solidity
function LandTileRange(uint32 tileCoordinate) public pure returns (uint32[], uint32[])
```

### getLandTilesEAW

```solidity
function getLandTilesEAW(uint32 LandId) public pure returns (uint256[])
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

### coordinateToXY

```solidity
function coordinateToXY(uint32 tileCoordinate) public pure returns (struct TileMath.XYCoordinate xycoordinate)
```

