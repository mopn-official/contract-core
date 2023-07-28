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

    uint256 public immutable bombPrice = 1000000000000;

    /**
     * @dev last active round and it's start timestamp and it's settlement status
     * @notice uint64 roundId + uint32 startTimestamp + uint8 round sold
     * Bits Layout:
     * - [0..7]      `round Sold`
     * - [8..39]     `starttimestamp`
     * - [40..103]    `roundId`
     */
    uint256 public bombRound;

    uint256 private constant _BITPOS_STARTTIMESTAMP = 8;
    uint256 private constant _BITPOS_ROUNDID = 40;

    /**
     * @dev record the deal price by round
     * @dev roundId => DealPrice
     */
    mapping(uint256 => uint256) public bombRoundData;

    /**
     * @dev record the last participate round auction data
     * @dev wallet address => uint64 total spend + uint64 roundId + uint8 auction amount
     *
     * Bits Layout:
     * - [0..7]     `auction amount`
     * - [8..71]    `roundId`
     * - [72..135]  `total spend`
     */
    mapping(address => uint256) public bombWalletData;
    uint256 private constant _BITPOS_WALLET_ROUNDID = 8;
    uint256 private constant _BITPOS_WALLET_TOTAL_SPEND = 72;

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
        _redeemAgio(msg.sender);

        uint256 price = getBombCurrentPrice() * amount;

        if (price > 0) {
            require(
                IMOPNToken(governance.mtContract()).balanceOf(msg.sender) >
                    price,
                "mopn token not enough"
            );
            IMOPNToken(governance.mtContract()).transferFrom(
                msg.sender,
                address(this),
                price
            );
        }

        _buyBomb(msg.sender, amount);
    }

    function _buyBomb(address buyer, uint256 amount) internal {
        uint256 roundId = getBombRoundId();
        uint256 roundSold = getBombRoundSold() + amount;
        require(roundSold <= bombRoundProduce, "round out of stock");
        uint256 currentPrice = getBombCurrentPrice();
        uint256 price = getBombCurrentPrice() * amount;

        governance.mintBomb(buyer, amount);

        bombWalletData[buyer] =
            ((getBombWalletTotalSpend(buyer) + price) <<
                _BITPOS_WALLET_TOTAL_SPEND) |
            (uint256(roundId) << _BITPOS_WALLET_ROUNDID) |
            uint256(getBombWalletAuctionAmount(buyer) + amount);

        if (roundSold >= bombRoundProduce) {
            settleBombPreviousRound(roundId, currentPrice);
            _redeemAgio(buyer);
        } else {
            bombRound += amount;
        }
        emit BombSold(buyer, amount, currentPrice);
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

    function getBombRoundSold() public view returns (uint256) {
        return uint8(bombRound);
    }

    function getBombWalletTotalSpend(
        address wallet
    ) public view returns (uint256) {
        return bombWalletData[wallet] >> _BITPOS_WALLET_TOTAL_SPEND;
    }

    function getBombWalletRoundId(address wallet) public view returns (uint64) {
        return uint64(bombWalletData[wallet] >> _BITPOS_WALLET_ROUNDID);
    }

    function getBombWalletAuctionAmount(
        address wallet
    ) public view returns (uint8) {
        return uint8(bombWalletData[wallet]);
    }

    function getBombRoundPrice(uint256 roundId) public view returns (uint256) {
        return bombRoundData[roundId];
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
     * @notice get the Specified wallet's agio amount
     * @param to the wallet address who is getting the agio
     */
    function getAgio(
        address to
    ) public view returns (uint256 agio, uint64 roundId) {
        if (bombWalletData[to] == 0) {
            return (0, 0);
        }
        roundId = getBombWalletRoundId(to);
        if (roundId != getBombRoundId()) {
            uint8 amount = getBombWalletAuctionAmount(to);
            agio =
                (getBombWalletTotalSpend(to) /
                    amount -
                    bombRoundData[roundId]) *
                amount;
        }
    }

    /**
     * @notice redeem the caller's agio
     */
    function redeemAgio() public {
        _redeemAgio(msg.sender);
    }

    function redeemAgioTo(address to) public {
        _redeemAgio(to);
    }

    function _redeemAgio(address to) internal {
        (uint256 agio, uint64 roundId) = getAgio(to);
        if (agio > 0) {
            bombWalletData[to] = 0;
            IMOPNToken(governance.mtContract()).transfer(to, agio);
            emit RedeemAgio(to, roundId, agio);
        }
    }

    /**
     * @notice make the last round settlement
     */
    function settleBombPreviousRound(uint256 roundId, uint256 price) internal {
        bombRoundData[roundId] = price;
        if (price > 0) {
            price = price * bombRoundProduce;
            IMOPNToken(governance.mtContract()).burn(price);
        }
        bombRound =
            (uint256(roundId + 1) << _BITPOS_ROUNDID) |
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

        _buyLand(msg.sender);
    }

    function _buyLand(address buyer) internal {
        uint256 roundStartTimestamp = getLandRoundStartTimestamp();
        require(block.timestamp >= roundStartTimestamp, "auction not start");

        uint64 roundId = getLandRoundId();

        IMOPNLand(governance.landContract()).auctionMint(buyer, 1);

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
                    _redeemAgio(from);
                    _checkTransferInAndRefund(
                        from,
                        value,
                        getBombCurrentPrice() * amount
                    );
                    _buyBomb(from, amount);
                }
            } else if (buyType == 2) {
                _checkTransferInAndRefund(from, value, getLandCurrentPrice());
                _buyLand(from);
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
