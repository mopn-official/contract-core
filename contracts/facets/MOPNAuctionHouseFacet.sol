// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {FacetCommons} from "./FacetCommons.sol";
import {Constants} from "../libraries/Constants.sol";
import {Events} from "../libraries/Events.sol";
import {LibMOPN} from "../libraries/LibMOPN.sol";
import "../interfaces/IMOPNBomb.sol";
import "../interfaces/IMOPNToken.sol";
import "../interfaces/IERC20Receiver.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title Arsenal for Bomb
/// @author Cyanface<cyanface@outlook.com>
contract MOPNAuctionHouseFacet is FacetCommons {
    /**
     * @notice buy the amount of bombs at current block's price
     * @param amount the amount of bombs
     */
    function buyBomb(uint256 amount) public {
        uint256 price = getBombCurrentPrice();

        if (price > 0) {
            IMOPNToken(LibMOPN.mopnStorage().tokenContract).mopnburn(msg.sender, price * amount);
        }

        _buyBomb(msg.sender, amount, price);
    }

    function _buyBomb(address buyer, uint256 amount, uint256 price) internal {
        increaseBombSold(amount);
        IMOPNBomb(LibMOPN.mopnStorage().bombContract).mint(buyer, 1, amount);
        emit Events.BombSold(buyer, amount, price);
    }

    function getBombSold() public view returns (LibMOPN.BombSoldStruct memory) {
        return LibMOPN.mopnStorage().bombsold;
    }

    function getLast24BombSold() public view returns (uint256 sold) {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        uint256 qactgap = block.timestamp - s.bombsold.lastSellTimestamp;
        if (qactgap < 86400) {
            uint256 currentIndex = (block.timestamp % 86400) / 3600;
            if (qactgap < 3600) {
                sold = s.bombsold.hourSolds[currentIndex];
            }
            uint256 endIndex = 24 - (qactgap / 3600);
            endIndex = (currentIndex + endIndex) % 24;
            currentIndex = (currentIndex + 1) % 24;
            while (currentIndex != endIndex) {
                sold += s.bombsold.hourSolds[currentIndex];
                currentIndex = (currentIndex + 1) % 24;
            }
        }
    }

    function increaseBombSold(uint256 amount) internal {
        LibMOPN.MOPNStorage storage s = LibMOPN.mopnStorage();
        uint256 qactgap = block.timestamp - s.bombsold.lastSellTimestamp;
        uint256 lastIndex = (s.bombsold.lastSellTimestamp % 86400) / 3600;
        uint256 currentIndex = (block.timestamp % 86400) / 3600;
        uint256 endIndex;
        if (qactgap >= 7200) {
            endIndex = (currentIndex + 1) % 24;
        } else {
            if (lastIndex == currentIndex) {
                if (qactgap >= 300) endIndex = (lastIndex + 1) % 24;
                else endIndex = lastIndex;
            } else {
                endIndex = (lastIndex + 1) % 24;
            }
        }
        while (currentIndex != endIndex) {
            s.bombsold.hourSolds[endIndex] = 0;
            endIndex = (endIndex + 1) % 24;
        }

        s.bombsold.lastSellTimestamp = uint32(block.timestamp);
        if (lastIndex != currentIndex || qactgap >= 3600) {
            s.bombsold.hourSolds[currentIndex] = uint16(amount);
        } else {
            if (amount + s.bombsold.hourSolds[currentIndex] > type(uint16).max) {
                s.bombsold.hourSolds[currentIndex] = type(uint16).max;
            } else {
                s.bombsold.hourSolds[currentIndex] += uint16(amount);
            }
        }
    }

    /**
     * @notice get the current auction price by block.timestamp
     * @return price current auction price
     */
    function getBombCurrentPrice() public view returns (uint256) {
        uint256 pmt = currentMTPPB(MTReduceTimes()) * 7200;
        uint256 pexp = (pmt * 7) / (LibMOPN.mopnStorage().TotalMOPNPoints / 5);
        int256 qexp = int256(pmt / (2 * pexp));

        return ABDKMath64x64.mulu(ABDKMath64x64.exp(ABDKMath64x64.divi(int256(getLast24BombSold()) - qexp, qexp)), pexp);
    }
}
