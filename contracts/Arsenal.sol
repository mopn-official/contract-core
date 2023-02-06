// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./interfaces/IMOPN.sol";

contract Arsenal {
    address public governanceContract;

    uint256 public roundTime = 79200;

    uint256 public roundProduce = 500;

    uint256 public startUnixRound;

    uint256 public startPrice = 1000000000000000000000000;

    mapping(uint256 => uint256) roundStorage;

    mapping(uint256 => uint256) roundDealPrice;

    mapping(uint256 => mapping(address => uint256)) roundAddressData;

    IEnergy public Energy;
    IGovernance public Governance;

    function setGovernanceContract(address governanceContract_) public {
        Governance = IGovernance(governanceContract_);
        Energy = IEnergy(Governance.energyContract());
    }

    function buy(uint256 amount) public {
        uint256 roundId = getCurrentRound();
        require(roundStorage[roundId] + amount < roundProduce, "stockoom");
        uint256 price = getCurrentPrice() * amount;
        require(price > 0, "round closed");
        require(Energy.balanceOf(msg.sender) > price, "energy not enough");
        Energy.transferFrom(msg.sender, address(this), price);
        Governance.mintBomb(msg.sender, amount);
        roundAddressData[roundId][msg.sender] += price * 10000 + amount * 10;
    }

    function getCurrentRound() public view returns (uint256) {
        return (block.timestamp / 86400) - startUnixRound;
    }

    function getCurrentPrice() public view returns (uint256 price) {
        uint256 roundId = getCurrentRound();
        if (roundStorage[roundId] == roundProduce) {
            return roundDealPrice[roundId];
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
        amoutLeft = roundProduce - roundStorage[roundId];
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
        amoutLeft = roundProduce - roundStorage[roundId];
        price = getRoundPrice(roundId);
        roundStartTime = 86400 * (startUnixRound + roundId);
        roundCloseTime = roundStartTime + roundTime;
    }

    function getRoundPrice(
        uint256 roundId
    ) public view returns (uint256 price) {
        uint256 amoutLeft = roundProduce - roundStorage[roundId];
        if (amoutLeft > 0) {
            price = 0;
        } else {
            price = roundDealPrice[roundId];
        }
    }

    function roundAgio(
        address to,
        uint256 roundId
    ) public view returns (uint256 agio) {
        require(
            roundAddressData[roundId][to] > 0 &&
                roundAddressData[roundId][to] % 10 == 0,
            "no agio"
        );
        uint256 amount = (roundAddressData[roundId][to] % 10000) / 10;
        agio =
            ((roundAddressData[roundId][to] / 10000) /
                amount -
                getRoundPrice(roundId)) *
            amount;
    }

    function redeemRoundAgio(uint256 roundId) public {
        uint256 agio = roundAgio(msg.sender, roundId);
        require(agio > 0, "no agio to redeem");
        roundAddressData[roundId][msg.sender] += 1;
        Energy.transfer(msg.sender, agio);
    }
}
