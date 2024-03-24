// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IMOPNCollectionVault.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IERC20Receiver.sol";
import "./libraries/LibCollectionVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract MOPNCollectionVault is IMOPNCollectionVault, ERC20, IERC20Receiver, IERC721Receiver {
    address public immutable mopn;

    uint8 public VaultStatus;
    uint32 public AskStartTimestamp;
    uint64 public AskAcceptPrice;
    uint32 public BidStartTimestamp;
    uint64 public BidAcceptPrice;
    uint256 public BidAcceptTokenId;

    constructor(address mopn_) ERC20("MOPN VToken", "MVT") {
        mopn = mopn_;
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked("MOPN VToken #", Strings.toString(IMOPN(mopn).getCollectionVaultIndex(collectionAddress()))));
    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked("MVT #", Strings.toString(IMOPN(mopn).getCollectionVaultIndex(collectionAddress()))));
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function collectionAddress() public view returns (address) {
        return LibCollectionVault.collectionAddress();
    }

    function getCollectionMOPNPoint() public view returns (uint24 point) {
        point = uint24((Math.sqrt(MTBalance() / 100) * 3) / 1000);

        if (AskAcceptPrice > 0) {
            uint24 maxPoint = uint24((Math.sqrt(AskAcceptPrice / 100) * 3) / 100);
            if (point > maxPoint) {
                point = maxPoint;
            }
        }
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getAskCurrentPrice() public view returns (uint256 price) {
        if (VaultStatus == 0) return 0;

        price = getAskPrice((block.timestamp - AskStartTimestamp) / 12);
        if (price < 1000000) {
            price = 1000000;
        }
    }

    function getAskPrice(uint256 reduceTimes) public view returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(9995, 10000);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, (BidAcceptPrice * 5) / 4);
    }

    function getAskInfo() public view returns (AskStruct memory auction) {
        auction.vaultStatus = VaultStatus;
        auction.startTimestamp = AskStartTimestamp;
        auction.bidAcceptPrice = BidAcceptPrice;
        auction.tokenId = BidAcceptTokenId;
        auction.currentPrice = getAskCurrentPrice();
    }

    function MT2VAmountRealtime(uint256 MTAmount, bool onReceived) public view returns (uint256 VAmount) {
        if (totalSupply() == 0) {
            VAmount = MTBalanceRealtime();
        } else {
            VAmount = (totalSupply() * MTAmount) / MTBalanceRealtime() - (onReceived ? MTAmount : 0);
        }
    }

    function MT2VAmount(uint256 MTAmount, bool onReceived) public view returns (uint256 VAmount) {
        uint256 balance = IMOPNToken(IMOPN(mopn).tokenContract()).balanceOf(address(this));
        if (totalSupply() == 0) {
            VAmount = balance;
        } else {
            VAmount = (totalSupply() * MTAmount) / (balance - (onReceived ? MTAmount : 0));
        }
    }

    function V2MTAmountRealtime(uint256 VAmount) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = MTBalanceRealtime();
        } else {
            MTAmount = (MTBalanceRealtime() * VAmount) / totalSupply();
        }
    }

    function V2MTAmount(uint256 VAmount) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = IMOPNToken(IMOPN(mopn).tokenContract()).balanceOf(address(this));
        } else {
            MTAmount = (IMOPNToken(IMOPN(mopn).tokenContract()).balanceOf(address(this)) * VAmount) / totalSupply();
        }
    }

    function withdraw(uint256 amount) public {
        address collectionAddress_ = LibCollectionVault.collectionAddress();
        IMOPN mopn_ = IMOPN(mopn);
        mopn_.claimCollectionMT(collectionAddress_);
        uint256 mtAmount = V2MTAmount(amount);
        require(mtAmount > 0, "zero to withdraw");
        IMOPNToken(mopn_.tokenContract()).transfer(msg.sender, mtAmount);
        _burn(msg.sender, amount);
        mopn_.settleCollectionMOPNPoint(collectionAddress_, getCollectionMOPNPoint());

        emit MTWithdraw(msg.sender, mtAmount, amount);
    }

    function MTBalanceRealtime() public view returns (uint256 amount) {
        amount =
            IMOPN(mopn).calcCollectionSettledMT(LibCollectionVault.collectionAddress()) +
            IMOPNToken(IMOPN(mopn).tokenContract()).balanceOf(address(this));
    }

    function MTBalance() public view returns (uint256 balance) {
        balance = IMOPNToken(IMOPN(mopn).tokenContract()).balanceOf(address(this));
    }

    function getBidCurrentPrice() public view returns (uint256) {
        return getBidPrice((block.timestamp - BidStartTimestamp) / 12);
    }

    function getBidPrice(uint256 increaseTimes) public view returns (uint256) {
        uint256 max = MTBalanceRealtime() / 5;
        uint64 AskAcceptPrice_ = (AskAcceptPrice * 3) / 4;
        if (AskAcceptPrice_ == 0 || AskAcceptPrice_ >= max) return max;
        uint256 maxIncreaseTimes = ABDKMath64x64.toUInt(
            ABDKMath64x64.div(
                ABDKMath64x64.ln(ABDKMath64x64.div(ABDKMath64x64.fromUInt(max), ABDKMath64x64.fromUInt(AskAcceptPrice_))),
                ABDKMath64x64.ln(ABDKMath64x64.div(10005, 10000))
            )
        );
        if (maxIncreaseTimes <= increaseTimes) return max;

        int128 increasePercentage = ABDKMath64x64.divu(10005, 10000);
        int128 increasePower = ABDKMath64x64.pow(increasePercentage, increaseTimes);
        return ABDKMath64x64.mulu(increasePower, AskAcceptPrice_);
    }

    function getBidInfo() public view returns (BidStruct memory bid) {
        bid.vaultStatus = VaultStatus;
        bid.startTimestamp = AskStartTimestamp;
        bid.askAcceptPrice = AskAcceptPrice;
        bid.currentPrice = getBidCurrentPrice();
    }

    function acceptBid(uint256 tokenId) public {
        require(VaultStatus == 0, "last ask not finish");
        address collectionAddress_ = LibCollectionVault.collectionAddress();

        IERC721(collectionAddress_).safeTransferFrom(msg.sender, address(this), tokenId, "0x");

        IMOPN mopn_ = IMOPN(mopn);

        mopn_.claimCollectionMT(collectionAddress_);

        uint256 offerPrice = getBidCurrentPrice();

        IMOPNToken(IMOPN(mopn).tokenContract()).transfer(msg.sender, offerPrice);

        BidStartTimestamp = 0;
        BidAcceptTokenId = tokenId;
        BidAcceptPrice = uint64(offerPrice);
        AskStartTimestamp = uint32(block.timestamp);
        VaultStatus = 1;

        mopn_.settleCollectionMOPNPoint(collectionAddress_, getCollectionMOPNPoint());

        emit BidAccept(msg.sender, tokenId, offerPrice);
    }

    function onERC20Received(address, address from, uint256 value, bytes calldata data) public returns (bytes4) {
        require(msg.sender == IMOPN(mopn).tokenContract(), "only accept mopn token");

        IMOPN mopn_ = IMOPN(mopn);

        address collectionAddress_ = LibCollectionVault.collectionAddress();

        if (bytes32(data) == keccak256("acceptAsk")) {
            require(VaultStatus == 1, "ask not exist");

            require(block.timestamp >= AskStartTimestamp, "ask not start");

            uint256 price = getAskCurrentPrice();
            require(value >= price, "MOPNToken not enough");

            if (value > price) {
                IMOPNToken(mopn_.tokenContract()).transfer(from, value - price);
                value = price;
            }
            uint256 burnAmount;
            if (price > 0) {
                burnAmount = price / 200;
                if (burnAmount > 0) {
                    IMOPNToken(mopn_.tokenContract()).burn(burnAmount);

                    price = price - burnAmount;
                }
            }

            mopn_.claimCollectionMT(collectionAddress_);
            mopn_.settleCollectionMOPNPoint(collectionAddress_, getCollectionMOPNPoint());

            IERC721(collectionAddress_).safeTransferFrom(address(this), from, BidAcceptTokenId, "0x");

            emit AskAccept(from, BidAcceptTokenId, price + burnAmount);

            VaultStatus = 0;
            AskStartTimestamp = 0;
            AskAcceptPrice = uint64(price + burnAmount);
            BidStartTimestamp = uint32(block.timestamp);
            BidAcceptPrice = 0;
            BidAcceptTokenId = 0;
        } else {
            require(VaultStatus == 0, "no staking during ask");
            mopn_.claimCollectionMT(collectionAddress_);

            uint256 vtokenAmount = MT2VAmount(value, true);
            require(vtokenAmount > 0, "need more mt to get at least 1 vtoken");
            _mint(from, vtokenAmount);
            mopn_.settleCollectionMOPNPoint(collectionAddress_, getCollectionMOPNPoint());

            emit MTDeposit(from, value, vtokenAmount);
        }

        return IERC20Receiver.onERC20Received.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
