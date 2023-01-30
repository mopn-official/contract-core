// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "./libraries/HexGridsMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error linkBlockError();

contract Avatar is Multicall, Ownable {
    using BlockMath for Block;
    using Math for uint256;

    mapping(uint256 => AvatarData) public avatarNoumenon;

    mapping(uint256 => mapping(uint256 => uint256)) public tokenMap;

    mapping(uint256 => uint256) public collectionMap;

    IMap public Map;

    IGovernance public Governance;

    IBomb public Bomb;

    uint256 public currentAvatarId;

    function setGovernanceContract(address governanceContract_) public {
        Governance = IGovernance(governanceContract_);
        Map = IMap(Governance.mapContract());
        Bomb = IBomb(Governance.bombContract());
    }

    function getAvatarOccupiedBlock(
        uint256 avatarId
    ) public view returns (Block memory) {
        return
            BlockMath.fromCoordinateInt(
                avatarNoumenon[avatarId].blockCoordinatInt
            );
    }

    function getAvatarOccupiedBlockInt(
        uint256 avatarId
    ) public view returns (uint64) {
        return avatarNoumenon[avatarId].blockCoordinatInt;
    }

    function mintAvatar(
        NFToken calldata token_,
        bytes32[] memory proofs
    ) public returns (uint256) {
        uint256 COID = Governance.checkWhitelistCOID(
            token_.collectionContract,
            proofs
        );
        require(tokenMap[COID][token_.tokenId] == 0, "avatar exist");

        currentAvatarId++;

        avatarNoumenon[currentAvatarId].COID = COID;
        avatarNoumenon[currentAvatarId].tokenId = token_.tokenId;

        tokenMap[COID][token_.tokenId] = currentAvatarId;
        return currentAvatarId;
    }

    function addBLER(uint256 avatarId, uint256 amount) public onlyMap {
        _addBLER(avatarId, amount);
    }

    function _addBLER(uint256 avatarId, uint256 amount) internal {
        avatarNoumenon[avatarId].BLER += amount;
    }

    function subBLER(uint256 avatarId, uint256 amount) public onlyMap {
        _subBLER(avatarId, amount);
    }

    function _subBLER(uint256 avatarId, uint256 amount) internal {
        avatarNoumenon[avatarId].BLER -= amount;
    }

    function moveTo(
        Block memory block_,
        uint256 linkedAvatarId,
        uint256 avatarId,
        uint16 blockPassId
    ) public blockCheck(block_) moveCheck(block_, linkedAvatarId, avatarId) {
        uint64 blockcoordinate = block_.coordinateInt();

        uint256 blerremove = 0;
        if (avatarNoumenon[avatarId].blockCoordinatInt != 0) {
            blerremove = Map.avatarRemove(
                avatarNoumenon[avatarId].blockCoordinatInt,
                avatarId
            );
        }

        avatarNoumenon[avatarId].blockCoordinatInt = blockcoordinate;

        uint256 bleradd = Map.avatarSet(
            avatarId,
            avatarNoumenon[avatarId].COID,
            blockcoordinate,
            blockPassId
        );

        if (bleradd > blerremove) {
            _addBLER(avatarId, bleradd - blerremove);
        } else if (bleradd < blerremove) {
            _subBLER(avatarId, blerremove - bleradd);
        }
    }

    function bomb(Block memory block_, uint256 avatarId) public {
        Bomb.burn(msg.sender, 1, 1);

        uint64[] memory blockSpheres = HexGridsMath.blockIntSpheres(
            block_.coordinateInt()
        );
        uint256 attackAvatarId = Map.getBlockAvatar(block_.coordinateInt());
        if (attackAvatarId != 0 && attackAvatarId != avatarId) {
            deFeat(attackAvatarId);
        }

        for (uint256 i = 0; i < blockSpheres.length; i++) {
            attackAvatarId = Map.getBlockAvatar(blockSpheres[i]);
            if (attackAvatarId == 0 || attackAvatarId == avatarId) {
                continue;
            }
            deFeat(attackAvatarId);
        }
    }

    function deFeat(uint256 avatarId) internal {
        require(
            avatarNoumenon[avatarId].blockCoordinatInt > 0,
            "avatar not on map"
        );
        uint256 bler = Map.avatarRemove(
            avatarNoumenon[avatarId].blockCoordinatInt,
            avatarId
        );
        if (bler > 0) {
            _subBLER(avatarId, bler);
        }
        avatarNoumenon[avatarId].blockCoordinatInt = 0;
    }

    function claimEnergy(uint256 avatarId) public {}

    modifier blockCheck(Block memory block_) {
        block_.check();
        require(
            Map.getBlockAvatar(block_.coordinateInt()) == 0,
            "block not available"
        );
        _;
    }

    modifier moveCheck(
        Block memory block_,
        uint256 linkedAvatarId,
        uint256 avatarId
    ) {
        if (linkedAvatarId > 0) {
            require(
                avatarNoumenon[avatarId].COID ==
                    avatarNoumenon[linkedAvatarId].COID,
                "link co error"
            );
            if (
                block_.distance(
                    BlockMath.fromCoordinateInt(
                        avatarNoumenon[linkedAvatarId].blockCoordinatInt
                    )
                ) > 3
            ) {
                revert linkBlockError();
            }
        } else if (collectionMap[avatarNoumenon[avatarId].COID] > 0) {
            revert linkBlockError();
        }
        _;
    }

    modifier onlyMap() {
        console.log(msg.sender);
        require(
            msg.sender == address(Map) || msg.sender == address(this),
            "not allowed"
        );
        _;
    }
}
