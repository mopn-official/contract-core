// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IGovernance.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @title Arsenal for Bomb
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract AuctionHouse is Multicall, Ownable {
    address public governanceContract;

    uint256 public bombRoundProduce = 100;

    /**
     * @dev last active round and it's start timestamp and it's settlement status
     * @notice roundId * 10 ** 14 + startTimestamp * 10 ** 3 + round sold
     */
    uint256 public bombRound;

    /**
     * @dev record the deal price by round
     * @dev roundId => DealPrice
     */
    mapping(uint256 => uint256) public bombRoundData;

    /**
     * @dev record the last participate round auction data
     * @dev wallet address => total spend * 10 ** 14 + auction amount * 10 ** 11 + roundId * 10 + agio redeem status
     */
    mapping(address => uint256) public bombWalletData;

    event BombSold(address indexed buyer, uint256 amount, uint256 price);

    IGovernance private Governance;

    constructor(uint256 bombStartTimestamp, uint256 landStartTimestamp) {
        bombRound = 10 ** 14 + bombStartTimestamp * 10 ** 3;
        landRound = 10 ** 11 + landStartTimestamp;
    }

    /**
     * @dev set the governance contract address
     * @dev this function also get the mopn token contract from the governances
     * @param governanceContract_ Governance Contract Address
     */
    function setGovernanceContract(
        address governanceContract_
    ) public onlyOwner {
        Governance = IGovernance(governanceContract_);
    }

    /**
     * @notice buy the amount of bombs at current block's price
     * @param amount the amount of bombs
     */
    function buyBomb(uint256 amount) public {
        uint256 roundStartTimestamp = getBombRoundStartTimestamp();
        require(block.timestamp > roundStartTimestamp, "auction not start");

        redeemAgio();

        uint256 roundId = getBombRoundId();
        uint256 roundSold = getBombRoundSold() + amount;
        require(roundSold <= bombRoundProduce, "round out of stock");
        uint256 currentPrice = getBombCurrentPrice();
        uint256 price = currentPrice * amount;

        if (price > 0) {
            require(
                IMOPNToken(Governance.mtContract()).balanceOf(msg.sender) >
                    price,
                "mopn token not enough"
            );
            IMOPNToken(Governance.mtContract()).transferFrom(
                msg.sender,
                address(this),
                price
            );
        }

        Governance.mintBomb(msg.sender, amount);

        bombWalletData[msg.sender] =
            (getBombWalletTotalSpend(msg.sender) + price) *
            10 ** 14 +
            amount *
            10 ** 11 +
            roundId *
            10;
        if (roundSold >= bombRoundProduce) {
            settleBombPreviousRound(roundId, currentPrice);
        } else {
            bombRound += amount;
        }
        emit BombSold(msg.sender, amount, currentPrice);
    }

    /**
     * @notice get current Round Id
     * @return roundId round Id
     */
    function getBombRoundId() public view returns (uint256 roundId) {
        roundId = bombRound / 10 ** 14;
    }

    function getBombRoundStartTimestamp()
        public
        view
        returns (uint256 startTimestamp)
    {
        startTimestamp = (bombRound % 10 ** 14) / 10 ** 3;
    }

    function getBombRoundSold() public view returns (uint256) {
        return bombRound % 10 ** 3;
    }

    function getBombWalletTotalSpend(
        address wallet
    ) public view returns (uint256) {
        return bombWalletData[wallet] / 10 ** 14;
    }

    function getBombWalletAuctionAmount(
        address wallet
    ) public view returns (uint256) {
        return (bombWalletData[wallet] % 10 ** 14) / 10 ** 11;
    }

    function getBombWalletRoundId(
        address wallet
    ) public view returns (uint256) {
        return (bombWalletData[wallet] % 10 ** 11) / 10;
    }

    function getBombWalletAgioRedeemStatus(
        address wallet
    ) public view returns (uint256) {
        return bombWalletData[wallet] % 10;
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

    uint256[] public bombPriceMap = [
        100000000000000,
        4904089407127,
        240500929130,
        11794380588,
        578406967,
        28365593,
        1391072,
        68218,
        3344,
        162
    ];

    uint256 bombZeroTrigger = 3090;

    function getBombPrice(
        uint256 reduceTimes
    ) public view returns (uint256 price) {
        if (reduceTimes <= bombZeroTrigger) {
            uint256 mapKey = reduceTimes / 300;
            if (mapKey >= bombPriceMap.length) {
                mapKey = bombPriceMap.length - 1;
            }
            price = bombPriceMap[mapKey];
            reduceTimes -= mapKey * 300;
            while (true) {
                if (reduceTimes > 30) {
                    price = (price * 99 ** 30) / (100 ** 30);
                } else {
                    price = (price * 99 ** reduceTimes) / (100 ** reduceTimes);
                    break;
                }
                reduceTimes -= 30;
            }
        }
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
    function getAgio(address to) public view returns (uint256 agio) {
        if (bombWalletData[to] == 0) {
            return 0;
        }
        if (getBombWalletAgioRedeemStatus(to) == 1) {
            return 0;
        }
        uint256 roundId = getBombWalletRoundId(to);
        if (roundId != getBombRoundId()) {
            uint256 amount = getBombWalletAuctionAmount(to);
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

    function redeemAgioTo(address to) public onlyOwner {
        _redeemAgio(to);
    }

    function _redeemAgio(address to) internal {
        uint256 agio = getAgio(to);
        if (agio > 0) {
            bombWalletData[to] = 0;
            IMOPNToken(Governance.mtContract()).transfer(to, agio);
        }
    }

    /**
     * @notice make the last round settlement
     */
    function settleBombPreviousRound(uint256 roundId, uint256 price) internal {
        if (price > 0) {
            price = price * bombRoundProduce;
            IMOPNToken(Governance.mtContract()).burn(price);
        }
        bombRoundData[roundId] = price;
        bombRound = (roundId + 1) * 10 ** 14 + block.timestamp * 10 ** 3;
    }

    /**
     * @dev last active round's start timestamp
     * @notice roundId * 10 ** 11 + startTimestamp
     */
    uint256 public landRound;

    /**
     * @notice get current Land Round Id
     * @return roundId round Id
     */
    function getLandRoundId() public view returns (uint256 roundId) {
        roundId = landRound / 10 ** 11;
    }

    function getLandRoundStartTimestamp()
        public
        view
        returns (uint256 startTimestamp)
    {
        startTimestamp = (landRound % 10 ** 11);
    }

    /**
     * @notice buy one land at current block's price
     */
    function buyLand() public {
        uint256 roundStartTimestamp = getLandRoundStartTimestamp();
        require(block.timestamp > roundStartTimestamp, "auction not start");

        uint256 roundId = getLandRoundId();
        uint256 price = getLandCurrentPrice();

        if (price > 0) {
            require(
                IMOPNToken(Governance.mtContract()).balanceOf(msg.sender) >
                    price,
                "MOPNToken not enough"
            );
            IMOPNToken(Governance.mtContract()).burnFrom(msg.sender, price);
        }

        Governance.mintLand(msg.sender);

        landRound = (roundId + 1) * 10 ** 11 + block.timestamp;
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

    uint256[] public landPriceMap = [
        1000000000000000,
        49040894071284,
        2405009291309,
        117943805894,
        5784069689,
        283655947,
        13910739,
        682193,
        33453,
        1639,
        79
    ];

    uint256 landZeroTrigger = 3330;

    function getLandPrice(
        uint256 reduceTimes
    ) public view returns (uint256 price) {
        if (reduceTimes <= landZeroTrigger) {
            uint256 mapKey = reduceTimes / 300;
            if (mapKey >= landPriceMap.length) {
                mapKey = landPriceMap.length - 1;
            }
            price = landPriceMap[mapKey];
            reduceTimes -= mapKey * 300;
            while (true) {
                if (reduceTimes > 30) {
                    price = (price * 99 ** 30) / (100 ** 30);
                } else {
                    price = (price * 99 ** reduceTimes) / (100 ** reduceTimes);
                    break;
                }
                reduceTimes -= 30;
            }
        }
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
