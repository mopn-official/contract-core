// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IMOPNToken.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IMiningData.sol";
import "./interfaces/IERC20Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract MOPNCollectionVault is ERC20, IERC20Receiver, Ownable {
    uint256 public COID;

    bool public isInitialized = false;

    IGovernance public immutable governance;

    /**
     * @notice NFTOfferData
     * Bits Layouts:
     *  - [0..0] OfferStatus 0 offering 1 auctioning
     *  - [1..32] Auction Start Timestamp
     *  - [33..96] Offer Accept Price
     *  - [97..255] Auction tokenId
     */
    uint256 public NFTOfferData;

    constructor(address governance_) ERC20("MOPN V-Token", "MVT") {
        governance = IGovernance(governance_);
    }

    function getOfferStatus() public view returns (uint256) {
        return NFTOfferData & 0xF;
    }

    function getAuctionStartTimestamp() public view returns (uint256) {
        return uint32(NFTOfferData >> 1);
    }

    function getOfferAcceptPrice() public view returns (uint256) {
        return uint64(NFTOfferData >> 33);
    }

    function getAuctionTokenId() public view returns (uint256) {
        return NFTOfferData >> 97;
    }

    function initialize(uint256 COID_) public {
        require(isInitialized == false, "contract initialzed");
        COID = COID_;
        isInitialized = true;
    }

    function MT2VAmount(
        uint256 MTAmount
    ) public view returns (uint256 VAmount) {
        if (totalSupply() == 0) {
            VAmount = MTAmount * 10 ** 10;
        } else {
            VAmount =
                (totalSupply() * MTAmount) /
                IMOPNToken(governance.mtContract()).balanceOf(address(this));
        }
    }

    function V2MTAmount(
        uint256 VAmount
    ) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = IMOPNToken(governance.mtContract()).balanceOf(
                address(this)
            );
        } else {
            MTAmount =
                (IMOPNToken(governance.mtContract()).balanceOf(address(this)) *
                    VAmount) /
                totalSupply();
        }
    }

    function withdraw(uint256 amount) public {
        IMiningData(governance.miningDataContract()).calcCollectionMTAW(COID);
        uint256 mtAmount = V2MTAmount(amount);
        require(mtAmount > 0, "zero to withdraw");
        IMOPNToken(governance.mtContract()).transferFrom(
            address(this),
            msg.sender,
            mtAmount
        );
        _burn(msg.sender, amount);
        IMiningData(governance.miningDataContract()).changeTotalMTPledge(
            COID,
            false,
            mtAmount
        );
    }

    function getNFTOfferPrice() public view returns (uint256) {
        uint256 amount = IMiningData(governance.miningDataContract())
            .getCollectionInboxMT(COID) +
            IMOPNToken(governance.mtContract()).balanceOf(address(this));

        return
            (amount *
                IMiningData(governance.miningDataContract())
                    .NFTOfferCoefficient()) / 10 ** 18;
    }

    function MTBalance() public view returns (uint256 balance) {
        balance = IMOPNToken(governance.mtContract()).balanceOf(address(this));
        if (getOfferStatus() == 1) {
            balance += getOfferAcceptPrice();
        }
    }

    function acceptNFTOffer(uint256 tokenId) public {
        require(getOfferStatus() == 0, "last offer auction not finish");

        IERC721(governance.getCollectionContract(COID)).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            "0x"
        );

        IMiningData(governance.miningDataContract()).calcCollectionMTAW(COID);

        uint256 offerPrice = (IMOPNToken(governance.mtContract()).balanceOf(
            address(this)
        ) *
            IMiningData(governance.miningDataContract())
                .NFTOfferCoefficient()) / 10 ** 18;

        IMOPNToken(governance.mtContract()).transfer(msg.sender, offerPrice);

        NFTOfferData =
            (tokenId << 97) |
            (offerPrice << 33) |
            (block.timestamp << 1) |
            1;

        IMiningData(governance.miningDataContract()).NFTOfferAcceptNotify(
            offerPrice
        );
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getAuctionCurrentPrice() public view returns (uint256) {
        if (getOfferStatus() == 0) return 0;

        return
            getAuctionPrice(
                (block.timestamp - getAuctionStartTimestamp()) / 60
            );
    }

    function getAuctionPrice(
        uint256 reduceTimes
    ) public view returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, getOfferAcceptPrice() * 2);
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public returns (bytes4) {
        require(
            msg.sender == governance.mtContract(),
            "only accept mopn token"
        );

        if (bytes32(data) == keccak256("acceptAuctionBid")) {
            require(getOfferStatus() == 1, "auction not exist");

            uint256 startTimestamp = getAuctionStartTimestamp();
            require(block.timestamp >= startTimestamp, "auction not start");

            uint256 price = getAuctionCurrentPrice();

            require(value >= price, "MOPNToken not enough");

            if (price > 0) {
                uint256 burnAmount = (price * 2) / 10;
                IMOPNToken(governance.mtContract()).burn(burnAmount);

                price = price - burnAmount;
            }

            if (value > price) {
                IMOPNToken(governance.mtContract()).transfer(
                    from,
                    value - price
                );
            }

            IMiningData(governance.miningDataContract()).calcCollectionMTAW(
                COID
            );
            uint256 offerAcceptPrice = getOfferAcceptPrice();
            if (price > offerAcceptPrice) {
                IMiningData(governance.miningDataContract())
                    .changeTotalMTPledge(COID, true, price - offerAcceptPrice);
            } else if (price < offerAcceptPrice) {
                IMiningData(governance.miningDataContract())
                    .changeTotalMTPledge(COID, false, offerAcceptPrice - price);
            }
            NFTOfferData = 0;
        } else {
            IMiningData(governance.miningDataContract()).calcCollectionMTAW(
                COID
            );

            uint256 vtokenAmount = MT2VAmount(value);
            _mint(from, vtokenAmount);
            IMiningData(governance.miningDataContract()).changeTotalMTPledge(
                COID,
                true,
                value
            );
        }

        return IERC20Receiver.onERC20Received.selector;
    }
}
