// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library MOPNBitMap {
    /// MiningData

    function MTTotalMinted(uint256 MiningData) public pure returns (uint256) {
        return uint64(MiningData >> 192);
    }

    function LastTickTimestamp(
        uint256 MiningData
    ) public pure returns (uint256) {
        return uint32(MiningData >> 160);
    }

    function TotalAdditionalMOPNPoints(
        uint256 MiningData
    ) public pure returns (uint256) {
        return uint48(MiningData >> 112);
    }

    function TotalMOPNPoints(uint256 MiningData) public pure returns (uint256) {
        return uint64(MiningData >> 48);
    }

    function PerMOPNPointMinted(
        uint256 MiningData
    ) public pure returns (uint256) {
        return uint48(MiningData);
    }

    /// MiningDataExt
    function AdditionalFinishSnapshot(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint48(MiningDataExt >> 184);
    }

    function NFTOfferCoefficient(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint48(MiningDataExt >> 136);
    }

    function TotalCollectionClaimed(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint48(MiningDataExt >> 88);
    }

    function TotalMTStaking(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint64(MiningDataExt >> 24);
    }

    function CurrentCollectionIndex(
        uint256 MiningDataExt
    ) public pure returns (uint256) {
        return uint24(MiningDataExt);
    }

    /// CollectionData

    function CollectionIndex(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint24(CollectionData >> 232);
    }

    function CollectionSettledMT(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint48(CollectionData >> 184);
    }

    function PerCollectionNFTMinted(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint48(CollectionData >> 136);
    }

    function CollectionPerMOPNPointMinted(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint48(CollectionData >> 88);
    }

    function CollectionMOPNPoint(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint24(CollectionData >> 64);
    }

    function CollectionMOPNPoints(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return
            uint24(CollectionData >> 64) * CollectionOnMapNum(CollectionData);
    }

    function CollectionAdditionalMOPNPoint(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint16(CollectionData >> 48);
    }

    function CollectionAdditionalMOPNPoints(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return
            uint16(CollectionData >> 48) * CollectionOnMapNum(CollectionData);
    }

    function CollectionOnMapNum(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint16(CollectionData >> 32);
    }

    function CollectionOnMapMOPNPoints(
        uint256 CollectionData
    ) public pure returns (uint256) {
        return uint32(CollectionData);
    }

    /// AccountData

    function AccountCollectionIndex(
        uint256 AccountData
    ) public pure returns (uint256) {
        return uint24(AccountData >> 176);
    }

    function AccountSettledMT(
        uint256 AccountData
    ) public pure returns (uint256) {
        return uint48(AccountData >> 128);
    }

    function AccountPerCollectionNFTMinted(
        uint256 AccountData
    ) public pure returns (uint256) {
        return uint48(AccountData >> 80);
    }

    function AccountPerMOPNPointMinted(
        uint256 AccountData
    ) public pure returns (uint256) {
        return uint48(AccountData >> 32);
    }

    function AccountCoordinate(
        uint256 AccountData
    ) public pure returns (uint32) {
        return uint32(AccountData);
    }

    /// TileData

    function TileCollectionIndex(
        uint256 TileData
    ) public pure returns (uint256) {
        return uint24(TileData >> 192);
    }

    function TileAccount(uint256 TileData) public pure returns (address) {
        return address(uint160(TileData >> 32));
    }

    function TileAccountInt(uint256 TileData) public pure returns (uint256) {
        return uint160(TileData >> 32);
    }

    function TileLandId(uint256 TileData) public pure returns (uint32) {
        return uint32(TileData);
    }
}
