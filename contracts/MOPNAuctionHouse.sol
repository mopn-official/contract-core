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

    uint256 public immutable bombPrice = 10000000000;

    struct roundData {
        uint32 sold;
        uint32 startblock;
        uint32 produce;
        uint32 id;
        uint32 reFundNum;
        uint32 reFundIndex;
    }

    roundData public bombRound;

    /**
     * @dev record the last participate round auction data
     *
     * Bits Layout:
     * - [0..15]      `auction amount`
     * - [16..63]     `price`
     * - [64..95]     `round Id`
     * - [96..255]    `address`
     */
    uint256[5] private reFundQueue;

    uint256 private constant _BITPOS_REFUND_PRICE = 16;
    uint256 private constant _BITPOS_REFUND_ROUND_ID = 64;
    uint256 private constant _BITPOS_REFUND_ADDRESS = 96;

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
        uint32 bombStartBlock,
        uint256 landStartTimestamp
    ) {
        governance = IMOPNGovernance(governance_);
        bombRound.id = 1;
        bombRound.produce = 10;
        bombRound.startblock = bombStartBlock;
        bombRound.reFundIndex = 4;

        landRound = (uint256(1) << _BITPOS_LAND_ROUNDID) | landStartTimestamp;
    }

    function bombCurrentProduce() public view returns (uint256 amount) {
        amount = (IMOPNLand(governance.landContract()).nextTokenId() - 1) / 10;
        if (amount < 10) {
            amount = 10;
        }
    }

    function getNextRefundIndex(uint32 index) public pure returns (uint32) {
        if (index == 4) {
            return 0;
        }
        return ++index;
    }

    function reFundPush(uint256 sellData) internal {
        uint32 index = (bombRound.reFundIndex + bombRound.reFundNum + 1) % 5;
        reFundQueue[index] = sellData;
        if (bombRound.reFundNum == 5) {
            bombRound.reFundIndex = getNextRefundIndex(bombRound.reFundIndex);
        } else {
            bombRound.reFundNum++;
        }
    }

    function claimRefund(uint256 sellData, uint256 price) public {
        uint256 sellPrice = uint48(sellData >> _BITPOS_REFUND_PRICE);
        if (sellPrice > price) {
            address to = address(uint160(sellData >> _BITPOS_REFUND_ADDRESS));
            uint256 amount = (sellPrice - price) * uint16(sellData);
            IMOPNToken(governance.mtContract()).transfer(to, amount);

            emit RedeemAgio(
                to,
                uint32(sellData >> _BITPOS_REFUND_ROUND_ID),
                amount
            );
        }

        IMOPNToken(governance.mtContract()).burn(price * uint16(sellData));
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
        console.log("price", price);
        uint256 roundSold = bombRound.sold + amount;
        require(roundSold <= bombRound.produce, "round out of stock");

        governance.mintBomb(buyer, 1, amount);

        if (roundSold == bombRound.produce) {
            if (bombRound.reFundNum > 0) {
                for (uint256 i = 0; i < bombRound.reFundNum; i++) {
                    uint256 index = (bombRound.reFundIndex + i) % 5;
                    claimRefund(reFundQueue[index], price);
                    reFundQueue[index] = 0;
                }
            }
            bombRound.id++;
            bombRound.produce = uint32(bombCurrentProduce());
            bombRound.startblock = uint32(block.number);
            bombRound.sold = 0;
            bombRound.reFundIndex = 4;
            bombRound.reFundNum = 0;

            IMOPNToken(governance.mtContract()).burn(price * amount);
        } else {
            if (bombRound.reFundNum == 5) {
                claimRefund(reFundQueue[bombRound.reFundIndex], price);
            }

            uint256 sellData = (uint256(uint160(buyer)) <<
                _BITPOS_REFUND_ADDRESS) |
                (uint256(bombRound.id) << _BITPOS_REFUND_ROUND_ID) |
                (price << _BITPOS_REFUND_PRICE) |
                amount;
            reFundPush(sellData);
            bombRound.sold++;
        }

        emit BombSold(buyer, amount, price);
    }

    /**
     * @notice get the current auction price by block.timestamp
     * @return price current auction price
     */
    function getBombCurrentPrice() public view returns (uint256) {
        uint32 startblock = bombRound.startblock;
        if (startblock == 0 || startblock > block.number) {
            startblock = uint32(block.number);
        }
        return getBombPrice((block.number - startblock) / 5);
    }

    function getBombPrice(uint256 reduceTimes) public pure returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, bombPrice);
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
