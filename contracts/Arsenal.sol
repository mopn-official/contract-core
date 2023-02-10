// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract Arsenal is Multicall, Ownable {
    address public governanceContract;

    uint256 public roundTime = 82800;

    uint256 public roundProduce = 500;

    uint256 public startUnixRound;

    // 1 million energy
    uint256 public startPrice = 100000000000000;

    /**
     * @notice record how many bombs that already sold by round and it's deal price
     */
    mapping(uint256 => uint256) roundData;

    /**
     * @notice record auction data by wallet
     */
    mapping(address => uint256) walletData;

    /**
     * @notice round Id. the last digit records energy burn status
     */
    uint256 lastRound;

    IEnergy public Energy;
    IGovernance public Governance;

    function setGovernanceContract(
        address governanceContract_
    ) public onlyOwner {
        Governance = IGovernance(governanceContract_);
        Energy = IEnergy(Governance.energyContract());
    }

    function checkCurrentRoundFinish() public view returns (bool finish) {
        uint256 timeElapse = block.timestamp % 86400;
        if (timeElapse > roundTime) {
            finish = true;
        }
    }

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
            10 ** 21 +
            amount *
            10 ** 11 +
            roundId *
            10;
        lastRound = roundId * 10;
    }

    function getCurrentRound() public view returns (uint256) {
        return (block.timestamp / 86400) - startUnixRound;
    }

    function getCurrentPrice() public view returns (uint256 price) {
        uint256 roundId = getCurrentRound();
        if (getRoundSold(roundId) == roundProduce) {
            return getRoundDealPrice(roundId);
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

    function getRoundDealPrice(uint256 roundId) public view returns (uint256) {
        return roundData[roundId] / 1000000;
    }

    function getRoundPrice(
        uint256 roundId
    ) public view returns (uint256 price) {
        uint256 roundDealPrice = getRoundDealPrice(roundId);
        uint256 amoutLeft = roundProduce - getRoundSold(roundId);
        if (amoutLeft > 0) {
            price = 0;
        } else {
            price = roundDealPrice;
        }
    }

    function getRoundSold(uint256 roundId) public view returns (uint256) {
        return roundData[roundId] % 1000000;
    }

    function burnLastRound() public {
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

    function getAgio(address to) public view returns (uint256 agio) {
        if (walletData[to] == 0) {
            return 0;
        }
        if (walletData[to] % 10 == 1) {
            return 0;
        }
        uint256 roundId = (walletData[to] % 10 ** 11) / 10;
        if (roundId != getCurrentRound() || checkCurrentRoundFinish()) {
            uint256 spend = walletData[to] / 10 ** 21;
            uint256 amount = (walletData[to] % 10 ** 21) / 10 ** 11;

            agio = (spend / amount - getRoundPrice(roundId)) * amount;
        }
    }

    function redeemAgio() public {
        burnLastRound();
        uint256 agio = getAgio(msg.sender);
        if (agio > 0) {
            walletData[msg.sender] += 1;
            Energy.transfer(msg.sender, agio);
        }
    }
}
