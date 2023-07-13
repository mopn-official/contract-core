# Solidity API

## MopnDataHelper

### AvatarDataOutput

```solidity
struct AvatarDataOutput {
  address contractAddress;
  uint256 tokenId;
  uint256 avatarId;
  uint256 COID;
  uint256 BombUsed;
  uint256 inboxMT;
  uint256 MOPNPoint;
  uint32 tileCoordinate;
}
```

### CollectionDataOutput

```solidity
struct CollectionDataOutput {
  address contractAddress;
  uint256 COID;
  uint256 OnMapNum;
  uint256 AvatarNum;
  uint256 inboxMT;
  uint256 MOPNPoint;
  uint256 AvatarMOPNPoint;
}
```

### governance

```solidity
contract IGovernance governance
```

### avatar

```solidity
contract IAvatar avatar
```

### map

```solidity
contract IMap map
```

### miningData

```solidity
contract IMiningData miningData
```

### constructor

```solidity
constructor(address governanceContract_) public
```

### getAvatarByAvatarId

```solidity
function getAvatarByAvatarId(uint256 avatarId) public view returns (struct MopnDataHelper.AvatarDataOutput avatarData)
```

### getAvatarsByAvatarIds

```solidity
function getAvatarsByAvatarIds(uint256[] avatarIds) public view returns (struct MopnDataHelper.AvatarDataOutput[] avatarDatas)
```

### getAvatarByNFT

```solidity
function getAvatarByNFT(address collection, uint256 tokenId) public view returns (struct MopnDataHelper.AvatarDataOutput avatarData)
```

get avatar info by nft contractAddress and tokenId

#### Parameters

| Name       | Type    | Description                 |
| ---------- | ------- | --------------------------- |
| collection | address | collection contract address |
| tokenId    | uint256 | token Id                    |

#### Return Values

| Name       | Type                                   | Description                                |
| ---------- | -------------------------------------- | ------------------------------------------ |
| avatarData | struct MopnDataHelper.AvatarDataOutput | avatar data format struct AvatarDataOutput |

### getAvatarsByNFTs

```solidity
function getAvatarsByNFTs(address[] collections, uint256[] tokenIds) public view returns (struct MopnDataHelper.AvatarDataOutput[] avatarDatas)
```

get avatar infos by nft contractAddresses and tokenIds

#### Parameters

| Name        | Type      | Description                          |
| ----------- | --------- | ------------------------------------ |
| collections | address[] | array of collection contract address |
| tokenIds    | uint256[] | array of token Ids                   |

#### Return Values

| Name        | Type                                     | Description                                 |
| ----------- | ---------------------------------------- | ------------------------------------------- |
| avatarDatas | struct MopnDataHelper.AvatarDataOutput[] | avatar datas format struct AvatarDataOutput |

### getAvatarsByCoordinateRange

```solidity
function getAvatarsByCoordinateRange(uint32 startCoordinate, int32 width, int32 height) public view returns (struct MopnDataHelper.AvatarDataOutput[] avatarDatas)
```

get avatar infos by tile sets start by start coordinate and range by width and height

#### Parameters

| Name            | Type   | Description           |
| --------------- | ------ | --------------------- |
| startCoordinate | uint32 | start tile coordinate |
| width           | int32  | range width           |
| height          | int32  | range height          |

### getAvatarsByStartEndCoordinate

```solidity
function getAvatarsByStartEndCoordinate(uint32 startCoordinate, uint32 endCoordinate) public view returns (struct MopnDataHelper.AvatarDataOutput[] avatarDatas)
```

get avatar infos by tile sets start by start coordinate and end by end coordinates

#### Parameters

| Name            | Type   | Description           |
| --------------- | ------ | --------------------- |
| startCoordinate | uint32 | start tile coordinate |
| endCoordinate   | uint32 | end tile coordinate   |

### getAvatarsByCoordinates

```solidity
function getAvatarsByCoordinates(uint32[] coordinates) public view returns (struct MopnDataHelper.AvatarDataOutput[] avatarDatas)
```

get avatars by coordinate array

#### Parameters

| Name        | Type     | Description          |
| ----------- | -------- | -------------------- |
| coordinates | uint32[] | array of coordinates |

#### Return Values

| Name        | Type                                     | Description                                 |
| ----------- | ---------------------------------------- | ------------------------------------------- |
| avatarDatas | struct MopnDataHelper.AvatarDataOutput[] | avatar datas format struct AvatarDataOutput |

### getBatchAvatarInboxMT

```solidity
function getBatchAvatarInboxMT(uint256[] avatarIds) public view returns (uint256[] inboxMTs)
```

### getCollectionInfo

```solidity
function getCollectionInfo(uint256 COID) public view returns (struct MopnDataHelper.CollectionDataOutput cData)
```

get collection contract, on map num, avatar num etc from IGovernance.

### getBatchCollectionInfo

```solidity
function getBatchCollectionInfo(uint256[] COIDs) public view returns (struct MopnDataHelper.CollectionDataOutput[] cDatas)
```
