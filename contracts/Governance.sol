// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    uint256 constant BEP = 6000000000000000000000;

    uint256 constant BEP_REDUCE_INTERVAL = 50000;

    uint256 BEPStartBlock;

    uint256 BEPSMinted;

    uint256 BEPSLastMiningBlockNumber;

    uint256 BEPSMiningShares;

    mapping(uint256 => uint256) public AvatarCalcBlockNumber;

    mapping(uint256 => uint256) public AvatarCalcEnergy;

    mapping(uint256 => uint256) public AvatarBLERShare;

    mapping(uint256 => uint256) public AvatarInboxEnergy;

    function addBEPS(uint256 avatarId, uint256 amount) public onlyAvatar {
        mintShareEnergy();
    }

    function subBEPS(uint256 avatarId, uint256 amount) public onlyAvatar {
        mintShareEnergy();
    }

    function mintShareEnergy() public {
        if (BEPSMiningShares == 0) {
            BEPSLastMiningBlockNumber = block.number;
        } else if (block.number > BEPSLastMiningBlockNumber) {
            uint256 reduceTimes = (BEPSLastMiningBlockNumber - BEPStartBlock) /
                BEP_REDUCE_INTERVAL;
            uint256 rangeTotalReduceTimes = ((block.number - BEPStartBlock) /
                BEP_REDUCE_INTERVAL) -
                reduceTimes +
                1;
            uint256 curBEP;
            uint256 reduceMaxBlockNumber;
            uint256 blocks;
            for (uint256 i = 0; i < rangeTotalReduceTimes; i++) {
                reduceMaxBlockNumber =
                    BEPStartBlock +
                    (reduceTimes + i) *
                    BEP_REDUCE_INTERVAL;
                curBEP = currentBEP(reduceTimes + i);

                if (block.number > reduceMaxBlockNumber) {
                    blocks = reduceMaxBlockNumber - BEPSLastMiningBlockNumber;
                    BEPSLastMiningBlockNumber = reduceMaxBlockNumber;
                } else {
                    blocks = block.number - BEPSLastMiningBlockNumber;
                }

                BEPSMinted += (blocks * curBEP) / BEPSMiningShares;
            }
            BEPSLastMiningBlockNumber = block.number;
        }
    }

    function currentBEP(uint256 reduceTimes) public pure returns (uint256) {
        return (BEP * 997 ** reduceTimes) / (1000 ** reduceTimes);
    }

    bytes32 public whiteListRoot;

    function checkWhitelistCOID(
        address collectionContract,
        bytes32[] memory proofs
    ) public returns (uint256) {
        if (COIDMap[collectionContract] == 0) {
            require(
                isInWhiteList(collectionContract, proofs),
                "not in whitelist"
            );
            generateCOID(collectionContract);
        }
        return COIDMap[collectionContract];
    }

    function isInWhiteList(
        address collectionContract,
        bytes32[] memory proofs
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                proofs,
                whiteListRoot,
                keccak256(
                    bytes.concat(keccak256(abi.encode(collectionContract)))
                )
            );
    }

    function updateWhiteList(bytes32 whiteListRoot_) public onlyOwner {
        whiteListRoot = whiteListRoot_;
    }

    address public avatarContract;

    function updateAvatarContract(address avatarContract_) public onlyOwner {
        avatarContract = avatarContract_;
    }

    address public bombContract;

    function updateBombContract(address bombContract_) public onlyOwner {
        bombContract = bombContract_;
    }

    address public energyContract;

    function updateEnergyContract(address energyContract_) public onlyOwner {
        energyContract = energyContract_;
    }

    address public mapContract;

    function updateMapContract(address mapContract_) public onlyOwner {
        mapContract = mapContract_;
    }

    function updatePassContract(address passContract_) public onlyOwner {
        passContract = passContract_;
    }

    address public passContract;

    // Collection Id
    uint256 COIDCounter;

    mapping(address => uint256) public COIDMap;

    function getCOID(address collectionContract) public view returns (uint256) {
        return COIDMap[collectionContract];
    }

    function generateCOID(address collectionContract) internal {
        COIDCounter++;
        COIDMap[collectionContract] = COIDCounter;
    }

    modifier onlyAvatar() {
        require(msg.sender == avatarContract, "not allowed");
        _;
    }

    modifier onlyMap() {
        require(msg.sender == mapContract, "not allowed");
        _;
    }
}
