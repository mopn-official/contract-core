// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNBomb.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNLand.sol";

import "./interfaces/IERC20Receiver.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title Arsenal for Bomb
/// @author Cyanface<cyanface@outlook.com>
contract MOPNAuctionHouse is Multicall {
    IMOPNGovernance public governance;

    event BombSold(address indexed buyer, uint256 amount, uint256 price);

    uint256 public constant landPrice = 1000000000000;

    uint32 public landRoundStartBlock;

    uint64 public landRoundId;

    event LandSold(address indexed buyer, uint256 price);

    modifier onlyMOPN() {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.auctionHouseContract(),
            "not allowed"
        );
        _;
    }

    constructor(address governance_, uint32 landStartBlock) {
        governance = IMOPNGovernance(governance_);
        landRoundStartBlock = landStartBlock;
        landRoundId = 1;
    }

    /**
     * @notice buy the amount of bombs at current block's price
     * @param amount the amount of bombs
     */
    function buyBomb(uint256 amount) public {
        uint256 price = getBombCurrentPrice();

        if (price > 0) {
            IMOPNToken(governance.tokenContract()).mopnburn(
                msg.sender,
                price * amount
            );
        }

        _buyBomb(msg.sender, amount, price);
    }

    function buyBombFrom(address from, uint256 amount) public onlyMOPN {
        uint256 price = getBombCurrentPrice();

        if (price > 0) {
            IMOPNToken(governance.tokenContract()).mopnburn(
                from,
                price * amount
            );
        }

        _buyBomb(from, amount, price);
    }

    function _buyBomb(address buyer, uint256 amount, uint256 price) internal {
        IMOPNBomb(governance.bombContract()).mint(buyer, 1, amount);
        emit BombSold(buyer, amount, price);
    }

    /**
     * @notice get the current auction price by block.timestamp
     * @return price current auction price
     */
    function getBombCurrentPrice() public view returns (uint256) {
        return
            (IMOPN(governance.mopnContract()).currentMTPPB() * 50000) /
            (91 * IMOPNLand(governance.landContract()).nextTokenId());
    }

    /**
     * @notice get current Land Round Id
     * @return roundId round Id
     */
    function getLandRoundId() public view returns (uint64) {
        return landRoundId;
    }

    function getLandRoundStartBlock() public view returns (uint32) {
        return landRoundStartBlock;
    }

    /**
     * @notice buy one land at current block's price
     */
    function buyLand() public {
        uint256 price = getLandCurrentPrice();

        if (price > 0) {
            require(
                IMOPNToken(governance.tokenContract()).balanceOf(msg.sender) >
                    price,
                "MOPNToken not enough"
            );
            IMOPNToken(governance.tokenContract()).mopnburn(msg.sender, price);
        }

        _buyLand(msg.sender, price);
    }

    function _buyLand(address buyer, uint256 price) internal {
        require(block.number >= landRoundStartBlock, "auction not start");

        IMOPNLand(governance.landContract()).auctionMint(buyer, 1);

        emit LandSold(buyer, price);

        landRoundId++;
        landRoundStartBlock = uint32(block.number);
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getLandCurrentPrice() public view returns (uint256) {
        if (landRoundStartBlock >= block.number) {
            return landPrice;
        }
        return getLandPrice((block.number - landRoundStartBlock) / 5);
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
        startTimestamp = landRoundStartBlock;
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes memory data
    ) public returns (bytes4) {
        require(
            msg.sender == governance.tokenContract(),
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
            IMOPNToken(governance.tokenContract()).burn(charge);
        }

        if (amount > charge) {
            IMOPNToken(governance.tokenContract()).transfer(
                from,
                amount - charge
            );
        }
    }
}
