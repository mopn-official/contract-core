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

    /**
     * @dev last active round and it's start timestamp and it's settlement status
     * @notice uint64 roundId + uint32 startTimestamp + uint32 BuyerNumber + uint32 Sold
     * Bits Layout:
     * - [0..31]        `round Sold`
     * - [32..63]       `round buyer number`
     * - [64..95]       `starttimestamp`
     * - [96..127]      `roundProduce`
     * - [128..191]     `roundId`
     */
    uint256 public bombRound;

    uint256 private constant _BITPOS_BUYER_NUMBER = 32;
    uint256 private constant _BITPOS_STARTTIMESTAMP = 64;
    uint256 private constant _BITPOS_ROUNDPRODUCE = 96;
    uint256 private constant _BITPOS_ROUNDID = 128;

    mapping(uint256 => uint256) bombRoundPrices;

    /**
     * @dev record the last participate round auction data
     *
     * Bits Layout:
     * - [0..63]        `auction amount`
     * - [64..127]      `total spend`
     * - [128..191]     `round Id`
     */
    mapping(address => uint256) public bombWalletData;

    uint256 private constant _BITPOS_WALLET_TOTAL_SPEND = 64;
    uint256 private constant _BITPOS_WALLET_ROUND_ID = 128;

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
            (uint256(10) << _BITPOS_ROUNDPRODUCE) |
            (bombStartTimestamp << _BITPOS_STARTTIMESTAMP);
        landRound = (uint256(1) << _BITPOS_LAND_ROUNDID) | landStartTimestamp;
    }

    function bombCurrentProduce() public view returns (uint256 amount) {
        amount = (IMOPNLand(governance.landContract()).nextTokenId() - 1) / 10;
        if (amount < 10) {
            amount = 10;
        }
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
        claimRefund(buyer);
        uint256 roundSold = getBombRoundSold() + amount;
        require(roundSold <= getBombRoundProduce(), "round out of stock");

        governance.mintBomb(buyer, 1, amount);

        if (bombWalletData[buyer] == 0) {
            bombWalletData[buyer] =
                (getBombRoundId() << _BITPOS_WALLET_ROUND_ID) |
                ((price * amount) << _BITPOS_WALLET_TOTAL_SPEND) |
                amount;
        } else {
            bombWalletData[buyer] +=
                ((price * amount) << _BITPOS_WALLET_TOTAL_SPEND) |
                amount;
        }

        if (roundSold >= getBombRoundProduce()) {
            settleBombRound(price);
            claimRefund(buyer);
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

    function getBombRoundProduce() public view returns (uint256) {
        return uint32(bombRound >> _BITPOS_ROUNDPRODUCE);
    }

    function getBombRoundStartTimestamp() public view returns (uint32) {
        return uint32(bombRound >> _BITPOS_STARTTIMESTAMP);
    }

    function getBombRoundBuyerNumber() public view returns (uint256) {
        return uint32(bombRound >> _BITPOS_BUYER_NUMBER);
    }

    function getBombRoundSold() public view returns (uint256) {
        return uint32(bombRound);
    }

    function getBombWalletAuctionAmount(
        address wallet
    ) public view returns (uint64) {
        return uint64(bombWalletData[wallet]);
    }

    function getBombWalletTotalSpend(
        address wallet
    ) public view returns (uint256) {
        return uint64(bombWalletData[wallet] >> _BITPOS_WALLET_TOTAL_SPEND);
    }

    function getBombWalletRoundId(
        address wallet
    ) public view returns (uint256) {
        return uint64(bombWalletData[wallet] >> _BITPOS_WALLET_ROUND_ID);
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
        amoutLeft = getBombRoundProduce() - getBombRoundSold();
        roundStartTime = getBombRoundStartTimestamp();
    }

    function getRefund(address wallet) public view returns (uint256 amount) {
        if (getBombWalletRoundId(wallet) < getBombRoundId()) {
            amount =
                getBombWalletTotalSpend(wallet) -
                (getBombWalletAuctionAmount(wallet) *
                    bombRoundPrices[getBombWalletRoundId(wallet)]);
        }
    }

    function claimRefund(address wallet) public {
        if (getBombWalletRoundId(wallet) >= getBombRoundId()) {
            return;
        }

        uint256 amount = getRefund(wallet);
        if (amount > 0) {
            IMOPNToken(governance.mtContract()).transfer(wallet, amount);
        }
        bombWalletData[wallet] = 0;
    }

    /**
     * @notice make the last round settlement
     */
    function settleBombRound(uint256 price) internal {
        uint256 roundId = getBombRoundId();
        if (price > 0) {
            IMOPNToken(governance.mtContract()).burn(
                price * getBombRoundProduce()
            );
            bombRoundPrices[roundId] = price;
        }
        bombRound =
            ((roundId + 1) << _BITPOS_ROUNDID) |
            (uint256(block.timestamp) << _BITPOS_STARTTIMESTAMP) |
            (bombCurrentProduce() << _BITPOS_ROUNDPRODUCE);
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
