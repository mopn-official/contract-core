// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMOPNToken.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/ILand.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title Arsenal for Bomb
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract AuctionHouse is Multicall, Ownable {
    address public governanceContract;

    uint8 public constant bombRoundProduce = 100;

    uint256 public constant bombPrice = 100000000000000;

    /**
     * @dev last active round and it's start timestamp and it's settlement status
     * @notice uint64 roundId + uint32 startTimestamp + uint8 round sold
     */
    uint256 public bombRound;

    /**
     * @dev record the deal price by round
     * @dev roundId => DealPrice
     */
    mapping(uint256 => uint256) public bombRoundData;

    /**
     * @dev record the last participate round auction data
     * @dev wallet address => uint64 total spend + uint64 roundId + uint8 auction amount + uint8 agio redeem status
     */
    mapping(address => uint256) public bombWalletData;

    event BombSold(address indexed buyer, uint256 amount, uint256 price);

    event RedeemAgio(address indexed to, uint256 roundId, uint256 amount);

    uint256 public constant landPrice = 1000000000000000;

    /**
     * @dev last active round's start timestamp
     * @notice uint64 roundId + uint32 startTimestamp
     */
    uint256 public landRound;

    constructor(uint256 bombStartTimestamp, uint256 landStartTimestamp) {
        bombRound = (uint256(1) << 192) | (bombStartTimestamp << 160);
        landRound = (uint256(1) << 192) | (landStartTimestamp << 160);
    }

    /**
     * @dev set the governance contract address
     * @dev this function also get the mopn token contract from the governances
     * @param governanceContract_ Governance Contract Address
     */
    function setGovernanceContract(
        address governanceContract_
    ) public onlyOwner {
        governanceContract = governanceContract_;
    }

    /**
     * @notice buy the amount of bombs at current block's price
     * @param amount the amount of bombs
     */
    function buyBomb(uint8 amount) public {
        uint256 roundStartTimestamp = getBombRoundStartTimestamp();
        require(block.timestamp > roundStartTimestamp, "auction not start");

        redeemAgio();

        uint64 roundId = getBombRoundId();
        uint8 roundSold = getBombRoundSold() + amount;
        require(roundSold <= bombRoundProduce, "round out of stock");
        uint256 currentPrice = getBombCurrentPrice();
        uint256 price = currentPrice * amount;

        if (price > 0) {
            require(
                IMOPNToken(IGovernance(governanceContract).mtContract())
                    .balanceOf(msg.sender) > price,
                "mopn token not enough"
            );
            IMOPNToken(IGovernance(governanceContract).mtContract())
                .transferFrom(msg.sender, address(this), price);
        }

        IGovernance(governanceContract).mintBomb(msg.sender, amount);

        bombWalletData[msg.sender] =
            (uint256(getBombWalletTotalSpend(msg.sender) + price) << 192) |
            (uint256(roundId) << 128) |
            (uint256(amount) << 120);

        if (roundSold >= bombRoundProduce) {
            settleBombPreviousRound(roundId, currentPrice);
        } else {
            bombRound =
                (bombRound &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00) |
                uint256(roundSold);
        }
        emit BombSold(msg.sender, amount, currentPrice);
    }

    /**
     * @notice get current Round Id
     * @return roundId round Id
     */
    function getBombRoundId() public view returns (uint64) {
        return uint64(bombRound >> 192);
    }

    function getBombRoundStartTimestamp() public view returns (uint32) {
        return uint32((bombRound >> 160) & 0xFFFFFFFF);
    }

    function getBombRoundSold() public view returns (uint8) {
        return uint8(bombRound);
    }

    function getBombWalletTotalSpend(
        address wallet
    ) public view returns (uint64) {
        return uint64(bombWalletData[wallet] >> 192);
    }

    function getBombWalletRoundId(address wallet) public view returns (uint64) {
        return uint64((bombWalletData[wallet] >> 128) & 0xFFFFFFFFFFFFFFFF);
    }

    function getBombWalletAuctionAmount(
        address wallet
    ) public view returns (uint8) {
        return uint8((bombWalletData[wallet] >> 120) & 0xFF);
    }

    function getBombWalletAgioRedeemStatus(
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
        if (getBombWalletAgioRedeemStatus(to) == 1) {
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
            IMOPNToken(IGovernance(governanceContract).mtContract()).transfer(
                to,
                agio
            );
            emit RedeemAgio(to, roundId, agio);
        }
    }

    /**
     * @notice make the last round settlement
     */
    function settleBombPreviousRound(uint64 roundId, uint256 price) internal {
        if (price > 0) {
            price = price * bombRoundProduce;
            IMOPNToken(IGovernance(governanceContract).mtContract()).burn(
                price
            );
        }
        bombRoundData[roundId] = price;
        bombRound =
            (uint256(roundId + 1) << 192) |
            (uint256(block.timestamp) << 160);
    }

    /**
     * @notice get current Land Round Id
     * @return roundId round Id
     */
    function getLandRoundId() public view returns (uint64) {
        return uint64(landRound >> 192);
    }

    function getLandRoundStartTimestamp() public view returns (uint32) {
        return uint32((landRound >> 160) & 0xFFFFFFFF);
    }

    /**
     * @notice buy one land at current block's price
     */
    function buyLand() public {
        uint256 roundStartTimestamp = getLandRoundStartTimestamp();
        require(block.timestamp > roundStartTimestamp, "auction not start");

        uint64 roundId = getLandRoundId();
        uint256 price = getLandCurrentPrice();

        if (price > 0) {
            require(
                IMOPNToken(IGovernance(governanceContract).mtContract())
                    .balanceOf(msg.sender) > price,
                "MOPNToken not enough"
            );
            IMOPNToken(IGovernance(governanceContract).mtContract()).burnFrom(
                msg.sender,
                price
            );
        }

        ILand(IGovernance(governanceContract).landContract()).auctionMint(
            msg.sender,
            1
        );

        landRound =
            (uint256(roundId + 1) << 192) |
            (uint256(block.timestamp) << 160);
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
}
