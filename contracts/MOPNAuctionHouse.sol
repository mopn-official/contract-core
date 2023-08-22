// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNLand.sol";
import "./interfaces/IERC20Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title Arsenal for Bomb
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract MOPNAuctionHouse is Multicall, Ownable {
    IMOPNGovernance public governance;

    uint8 public immutable bombRoundProduce = 10;

    uint256 public immutable bombPrice = 100000000000;

    /**
     * @dev last active round and it's start timestamp and it's settlement status
     * @notice uint64 roundId + uint32 startTimestamp + uint8 round sold
     * Bits Layout:
     * - [0..7]      `round Sold`
     * - [8..15]       `round buyer number`
     * - [16..47]     `starttimestamp`
     * - [48..111]    `roundId`
     */
    uint256 public bombRound;

    uint256 private constant _BITPOS_BUYER_NUMBER = 8;
    uint256 private constant _BITPOS_STARTTIMESTAMP = 16;
    uint256 private constant _BITPOS_ROUNDID = 48;

    /**
     * @dev record the last participate round auction data
     *
     * Bits Layout:
     * - [0..7]     `auction amount`
     * - [8..71]    `total spend`
     * - [72..231]  `buyer`
     */
    mapping(uint256 => uint256) public bombRoundBuyers;

    uint256 private constant _BITPOS_BUYER_TOTAL_SPEND = 8;
    uint256 private constant _BITPOS_BUYER_WALLET = 72;

    event BombSold(address indexed buyer, uint256 amount, uint256 price);

    event RedeemAgio(address indexed to, uint256 roundId, uint256 amount);

    uint256 public immutable landPrice = 1000000000000;

    /**
     * @dev last active round's start timestamp
     * @notice uint64 roundId + uint32 startTimestamp
     *  Bits Layout:
     *  - [0..31]      `start timestamp`
     *  - [32..95]     `round Id`
     */
    uint256 public landRound;

    uint256 private constant _BITPOS_LAND_ROUNDID = 32;

    event LandSold(address indexed buyer, uint256 price);

    constructor(
        address governance_,
        uint256 bombStartTimestamp,
        uint256 landStartTimestamp
    ) {
        governance = IMOPNGovernance(governance_);
        bombRound =
            (uint256(1) << _BITPOS_ROUNDID) |
            (bombStartTimestamp << _BITPOS_STARTTIMESTAMP);
        landRound = (uint256(1) << _BITPOS_LAND_ROUNDID) | landStartTimestamp;
    }

    /**
     * @notice buy the amount of bombs at current block's price
     * @param amount the amount of bombs
     */
    function buyBomb(uint8 amount) public {
        uint256 price = getBombCurrentPrice();

        if (price > 0) {
            require(
                IMOPNToken(governance.mtContract()).balanceOf(msg.sender) >
                    price * amount,
                "mopn token not enough"
            );
            IMOPNToken(governance.mtContract()).transferFrom(
                msg.sender,
                address(this),
                price * amount
            );
        }

        _buyBomb(msg.sender, amount, price);
    }

    function _buyBomb(address buyer, uint256 amount, uint256 price) internal {
        uint256 roundSold = getBombRoundSold() + amount;
        require(roundSold <= bombRoundProduce, "round out of stock");

        governance.mintBomb(buyer, 1, amount);

        bombRoundBuyers[getBombRoundBuyerNumber()] =
            (uint256(uint160(buyer)) << _BITPOS_BUYER_WALLET) |
            ((price * amount) << _BITPOS_BUYER_TOTAL_SPEND) |
            amount;

        if (roundSold >= bombRoundProduce) {
            settleBombRound(price);
        } else {
            bombRound += (uint256(1) << _BITPOS_BUYER_NUMBER) | amount;
        }
        emit BombSold(buyer, amount, price);
    }

    /**
     * @notice get current Round Id
     * @return roundId round Id
     */
    function getBombRoundId() public view returns (uint256) {
        return bombRound >> _BITPOS_ROUNDID;
    }

    function getBombRoundStartTimestamp() public view returns (uint32) {
        return uint32(bombRound >> _BITPOS_STARTTIMESTAMP);
    }

    function getBombRoundBuyerNumber() public view returns (uint256) {
        return uint8(bombRound >> _BITPOS_BUYER_NUMBER);
    }

    function getBombRoundSold() public view returns (uint256) {
        return uint8(bombRound);
    }

    function getBombBuyerAuctionAmount(
        uint256 index
    ) public view returns (uint8) {
        return uint8(bombRoundBuyers[index]);
    }

    function getBombBuyerTotalSpend(
        uint256 index
    ) public view returns (uint256) {
        return uint64(bombRoundBuyers[index] >> _BITPOS_BUYER_TOTAL_SPEND);
    }

    function getBombBuyerWallet(uint256 index) public view returns (address) {
        return address(uint160(bombRoundBuyers[index] >> _BITPOS_BUYER_WALLET));
    }

    /**
     * @notice get the current auction price by block.timestamp
     * @return price current auction price
     */
    function getBombCurrentPrice() public view returns (uint256) {
        uint256 roundStartTimestamp = getBombRoundStartTimestamp();
        if (roundStartTimestamp == 0 || roundStartTimestamp > block.timestamp) {
            roundStartTimestamp = block.timestamp;
        }
        return getBombPrice((block.timestamp - roundStartTimestamp) / 60);
    }

    function getBombPrice(uint256 reduceTimes) public pure returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, bombPrice);
    }

    /**
     * @notice a set of current round data
     * @return roundId round Id of current round
     * @return price
     * @return amoutLeft
     * @return roundStartTime round start timestamp
     */
    function getBombCurrentData()
        public
        view
        returns (
            uint256 roundId,
            uint256 price,
            uint256 amoutLeft,
            uint256 roundStartTime
        )
    {
        roundId = getBombRoundId();
        price = getBombCurrentPrice();
        amoutLeft = bombRoundProduce - getBombRoundSold();
        roundStartTime = getBombRoundStartTimestamp();
    }

    /**
     * @notice make the last round settlement
     */
    function settleBombRound(uint256 price) internal {
        if (price > 0) {
            IMOPNToken(governance.mtContract()).burn(price * bombRoundProduce);
        }
        for (uint256 i = 0; i < getBombRoundBuyerNumber(); i++) {
            uint256 amount = getBombBuyerTotalSpend(i) -
                (price * getBombBuyerAuctionAmount(i));
            if (amount > 0) {
                IMOPNToken(governance.mtContract()).transfer(
                    getBombBuyerWallet(i),
                    amount
                );
                emit RedeemAgio(
                    getBombBuyerWallet(i),
                    getBombRoundId(),
                    amount
                );
            }
        }
        bombRound =
            (uint256(getBombRoundId() + 1) << _BITPOS_ROUNDID) |
            (uint256(block.timestamp) << _BITPOS_STARTTIMESTAMP);
    }

    /**
     * @notice get current Land Round Id
     * @return roundId round Id
     */
    function getLandRoundId() public view returns (uint64) {
        return uint64(landRound >> _BITPOS_LAND_ROUNDID);
    }

    function getLandRoundStartTimestamp() public view returns (uint32) {
        return uint32(landRound);
    }

    /**
     * @notice buy one land at current block's price
     */
    function buyLand() public {
        uint256 price = getLandCurrentPrice();

        if (price > 0) {
            require(
                IMOPNToken(governance.mtContract()).balanceOf(msg.sender) >
                    price,
                "MOPNToken not enough"
            );
            IMOPNToken(governance.mtContract()).burnFrom(msg.sender, price);
        }

        _buyLand(msg.sender, price);
    }

    function _buyLand(address buyer, uint256 price) internal {
        uint256 roundStartTimestamp = getLandRoundStartTimestamp();
        require(block.timestamp >= roundStartTimestamp, "auction not start");

        uint64 roundId = getLandRoundId();

        IMOPNLand(governance.landContract()).auctionMint(buyer, 1);

        emit LandSold(buyer, price);

        landRound =
            (uint256(roundId + 1) << _BITPOS_LAND_ROUNDID) |
            block.timestamp;
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getLandCurrentPrice() public view returns (uint256) {
        uint256 roundStartTimestamp = getLandRoundStartTimestamp();
        if (roundStartTimestamp == 0 || roundStartTimestamp > block.timestamp) {
            roundStartTimestamp = block.timestamp;
        }
        return getLandPrice((block.timestamp - roundStartTimestamp) / 60);
    }

    function getLandPrice(uint256 reduceTimes) public pure returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, landPrice);
    }

    /**
     * @notice a set of current round data
     * @return roundId round Id of current round
     * @return price
     */
    function getLandCurrentData()
        public
        view
        returns (uint256 roundId, uint256 price, uint256 startTimestamp)
    {
        roundId = getLandRoundId();
        price = getLandCurrentPrice();
        startTimestamp = getLandRoundStartTimestamp();
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes memory data
    ) public returns (bytes4) {
        require(
            msg.sender == governance.mtContract(),
            "only accept mopn token"
        );

        if (data.length > 0) {
            (uint256 buyType, uint256 amount) = abi.decode(
                data,
                (uint256, uint256)
            );
            if (buyType == 1) {
                if (amount > 0) {
                    uint256 price = getBombCurrentPrice();
                    _checkTransferInAndRefund(from, value, price * amount);
                    _buyBomb(from, amount, price);
                }
            } else if (buyType == 2) {
                uint256 price = getLandCurrentPrice();
                _checkTransferInAndRefund(from, value, price);
                _buyLand(from, price);
                IMOPNToken(governance.mtContract()).burn(price);
            }
        }

        return IERC20Receiver.onERC20Received.selector;
    }

    function _checkTransferInAndRefund(
        address from,
        uint256 amount,
        uint256 charge
    ) internal {
        if (charge > 0) {
            require(amount >= charge, "mopn token not enough");
        }

        if (amount > charge) {
            IMOPNToken(governance.mtContract()).transfer(from, amount - charge);
        }
    }
}
