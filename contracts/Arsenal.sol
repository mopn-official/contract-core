// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @title Arsenal for Bomb
/// @author Cyanface<cyanface@outlook.com>
/// @dev This Contract's owner must transfer to Governance Contract once it's deployed
contract Arsenal is Multicall, Ownable {
    address public governanceContract;

    uint256 public roundTime = 82800;

    uint256 public roundProduce = 500;

    uint256 public startUnixRound;

    // 1 million energy
    uint256 public startPrice = 100000000000000;

    /**
     * @dev record the number of bombs that already sold and it's deal price by round
     * @dev roundId => DealPrice * 1000000 + roundSold
     */
    mapping(uint256 => uint256) roundData;

    /**
     * @dev record the last participate round auction data
     * @dev wallet address => total spend * 10 ** 17 + auction amount * 10 ** 11 + roundId * 10 + agio redeem status
     */
    mapping(address => uint256) walletData;

    /**
     * @dev last active round and it's settlement status
     * @dev round Id * 10 + settlement status
     */
    uint256 lastRound;

    IEnergy public Energy;
    IGovernance public Governance;

    /**
     * @dev set the governance contract address
     * @dev this function also get the energy contract from the governances
     * @param governanceContract_ Governance Contract Address
     */
    function setGovernanceContract(
        address governanceContract_
    ) public onlyOwner {
        Governance = IGovernance(governanceContract_);
        Energy = IEnergy(Governance.energyContract());
    }

    /**
     * @dev check if the current round is finish
     * @return finish finish status
     */
    function checkCurrentRoundFinish() public view returns (bool finish) {
        uint256 timeElapse = block.timestamp % 86400;
        if (timeElapse > roundTime) {
            finish = true;
        } else if (getRoundSold(getCurrentRound()) == roundProduce) {
            finish = true;
        }
    }

    /**
     * @notice buy the amount of bombs at current block's price
     * @param amount the amount of bombs
     */
    function buy(uint256 amount) public {
        redeemAgio();
        uint256 roundId = getCurrentRound();
        uint256 roundSold = getRoundSold(roundId);
        require(roundSold + amount <= roundProduce, "stockoom");
        uint256 currentPrice = getCurrentPrice();
        uint256 price = currentPrice * amount;
        require(price > 0, "round closed");
        require(Energy.balanceOf(msg.sender) > price, "energy not enough");
        Energy.transferFrom(msg.sender, address(this), price);
        Governance.mintBomb(msg.sender, amount);
        roundData[roundId] = currentPrice * 1000000 + roundSold + amount;
        walletData[msg.sender] +=
            price *
            10 ** 17 +
            amount *
            10 ** 11 +
            roundId *
            10;
        lastRound = roundId * 10;
    }

    /**
     * @notice get current Round Id
     * @return roundId round Id
     */
    function getCurrentRound() public view returns (uint256) {
        return (block.timestamp / 86400) - startUnixRound;
    }

    /**
     * @notice get the current auction price by block.timestamp
     * @return price current auction price
     */
    function getCurrentPrice() public view returns (uint256 price) {
        uint256 roundId = getCurrentRound();
        if (getRoundSold(roundId) == roundProduce) {
            return getRoundPrice(roundId);
        }
        uint256 timeElapse = block.timestamp % 86400;
        if (timeElapse >= roundTime) {
            return 0;
        }
        uint256 reduceTimes = timeElapse / 120;
        price = startPrice;
        while (true) {
            if (reduceTimes > 30) {
                price = (price * 49 ** 30) / (50 ** 30);
            } else {
                price = (price * 49 ** reduceTimes) / (50 ** reduceTimes);
                break;
            }
            reduceTimes -= 30;
        }
    }

    /**
     * @notice a set of current round data
     * @return roundId round Id of current round
     * @return price
     * @return amoutLeft
     * @return roundStartTime round start timestamp
     * @return roundCloseTime round close timestamp
     */
    function getCurrentRoundData()
        public
        view
        returns (
            uint256 roundId,
            uint256 price,
            uint256 amoutLeft,
            uint256 roundStartTime,
            uint256 roundCloseTime
        )
    {
        roundId = getCurrentRound();
        price = getCurrentPrice();
        amoutLeft = roundProduce - getRoundSold(roundId);
        roundStartTime = block.timestamp - (block.timestamp % 86400);
        roundCloseTime = roundStartTime + roundTime;
    }

    /**
     * @notice a set of Specified round data
     * @param roundId round Id
     * @return price final price
     * @return amoutLeft
     * @return roundStartTime round start timestamp
     * @return roundCloseTime round close timestamp
     */
    function getRoundData(
        uint256 roundId
    )
        public
        view
        returns (
            uint256 price,
            uint256 amoutLeft,
            uint256 roundStartTime,
            uint256 roundCloseTime
        )
    {
        amoutLeft = roundProduce - getRoundSold(roundId);
        price = getRoundPrice(roundId);
        roundStartTime = 86400 * (startUnixRound + roundId);
        roundCloseTime = roundStartTime + roundTime;
    }

    /**
     * @notice get Round Deal Price
     * @param roundId round Id
     * @return price round Deal Price
     */
    function getRoundPrice(
        uint256 roundId
    ) public view returns (uint256 price) {
        price = roundData[roundId] / 1000000;
        uint256 amoutLeft = roundProduce - getRoundSold(roundId);
        if (amoutLeft > 0) {
            price = 0;
        }
    }

    /**
     * @notice get Round Sold amount
     * @param roundId round Id
     * @return amount round sold amount
     */
    function getRoundSold(uint256 roundId) public view returns (uint256) {
        return roundData[roundId] % 1000000;
    }

    /**
     * @notice make the last round settlement if it's finished
     */
    function settleLastRound() public {
        uint256 burnStatus = lastRound % 10;
        uint256 roundId = lastRound / 10;
        if (
            burnStatus == 0 &&
            (roundId != getCurrentRound() || checkCurrentRoundFinish())
        ) {
            uint256 price = getRoundPrice(roundId) * getRoundSold(roundId);
            if (price > 0) {
                Energy.burnFrom(address(this), price);
            }
            lastRound += 1;
        }
    }

    /**
     * @notice get the Specified wallet's agio amount
     * @param to the wallet address who is getting the agio
     */
    function getAgio(address to) public view returns (uint256 agio) {
        if (walletData[to] == 0) {
            return 0;
        }
        if (walletData[to] % 10 == 1) {
            return 0;
        }
        uint256 roundId = (walletData[to] % 10 ** 11) / 10;
        if (roundId != getCurrentRound() || checkCurrentRoundFinish()) {
            uint256 spend = walletData[to] / 10 ** 17;
            uint256 amount = (walletData[to] % 10 ** 17) / 10 ** 11;

            agio = (spend / amount - getRoundPrice(roundId)) * amount;
        }
    }

    /**
     * @notice redeem the caller's agio
     */
    function redeemAgio() public {
        settleLastRound();
        uint256 agio = getAgio(msg.sender);
        if (agio > 0) {
            walletData[msg.sender] += 1;
            Energy.transfer(msg.sender, agio);
        }
    }
}
