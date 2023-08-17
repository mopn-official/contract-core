// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library MOPNBitMap {
    /// MiningData
    function TotalAdditionalMOPNPoints(
        uint256 MiningData
    ) public pure returns (uint256) {
        return uint48(MiningData >> 208);
    }

    function TotalMOPNPoints(uint256 MiningData) public pure returns (uint256) {
        return uint64(MiningData >> 144);
    }

    function LastTickTimestamp(
        uint256 MiningData
    ) public pure returns (uint256) {
        return uint32(MiningData >> 112);
    }

    function PerMOPNPointMinted(
        uint256 MiningData
    ) public pure returns (uint256) {
        return uint48(MiningData >> 64);
    }

    function MTTotalMinted(uint256 MiningData) public pure returns (uint256) {
        return uint64(MiningData);
    }

    /// MiningDataExt
    function AdditionalFinishSnapshot(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint48(MiningDataExt >> 160);
    }

    function NFTOfferCoefficient(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint48(MiningDataExt >> 112);
    }

    function TotalCollectionClaimed(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint48(MiningDataExt >> 64);
    }

    function TotalMTStaking(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint64(MiningDataExt);
    }

    /// CollectionData
    function CollectionAdditionalMOPNPoint(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint24(CollectionData >> 232);
    }

    function CollectionAdditionalMOPNPoints(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return
            uint24(CollectionData >> 232) * CollectionOnMapNum(CollectionData);
    }

    function CollectionMOPNPoint(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint24(CollectionData >> 208);
    }

    function CollectionMOPNPoints(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return
            uint24(CollectionData >> 208) * CollectionOnMapNum(CollectionData);
    }

    function CollectionOnMapMOPNPoints(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint32(CollectionData >> 176);
    }

    function CollectionOnMapNum(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint16(CollectionData >> 160);
    }

    function PerCollectionNFTMinted(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint48(CollectionData >> 112);
    }

    function CollectionPerMOPNPointMinted(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint48(CollectionData >> 64);
    }

    function CollectionSettledMT(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint64(CollectionData);
    }

    /// AccountData
    function AccountCoordinate(
        uint256 AccountData
    ) public pure returns (uint32) {
        return uint32(AccountData >> 160);
    }

    function AccountPerCollectionNFTMinted(
        uint256 AccountData
    ) public pure returns (uint256) {
        return uint48(AccountData >> 112);
    }

    function AccountPerMOPNPointMinted(
        uint256 AccountData
    ) public pure returns (uint256) {
        return uint48(AccountData >> 64);
    }

    function AccountSettledMT(
        uint256 AccountData
    ) public pure returns (uint256) {
        return uint64(AccountData);
    }

    /// TileData
    function TileAccount(uint256 TileData) public pure returns (address) {
        return address(uint160(TileData >> 32));
    }

    function TileAccountInt(uint256 TileData) public pure returns (uint256) {
        return uint160(TileData >> 32);
    }

    function TileLandId(uint256 TileData) public pure returns (uint32) {
        return uint32(TileData);
    }

    function get256bitmap(
        uint256 bitmap,
        uint256 index
    ) public pure returns (bool) {
        uint256 mask = 1 << (index & 0xff);
        return bitmap & mask != 0;
    }

    function set256bitmap(
        uint256 bitmap,
        uint256 index
    ) public pure returns (uint256) {
        uint256 mask = 1 << (index & 0xff);
        bitmap |= mask;
        return bitmap;
    }

    function unset256bitmap(
        uint256 bitmap,
        uint256 index
    ) public pure returns (uint256) {
        uint256 mask = 1 << (index & 0xff);
        bitmap &= ~mask;
        return bitmap;
    }
}
