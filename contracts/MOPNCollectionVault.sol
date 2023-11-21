// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./interfaces/IMOPNCollectionVault.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNData.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IERC20Receiver.sol";
import "./libraries/CollectionVaultLib.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract MOPNCollectionVault is
    IMOPNCollectionVault,
    ERC20,
    IERC20Receiver,
    IERC721Receiver
{
    address public immutable governance;

    uint8 OfferStatus;
    uint32 AuctionStartTimestamp;
    uint64 OfferAcceptPrice;
    uint256 AuctionTokenId;

    constructor(address governance_) ERC20("MOPN VToken", "MVT") {
        governance = governance_;
    }

    function name() public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "MOPN VToken",
                    " #",
                    Strings.toString(
                        IMOPNGovernance(governance).getCollectionVaultIndex(
                            collectionAddress()
                        )
                    )
                )
            );
    }

    function symbol() public pure override returns (string memory) {
        return "MVT";
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function collectionAddress() public view returns (address) {
        return CollectionVaultLib.collectionAddress();
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getAuctionCurrentPrice() public view returns (uint256) {
        if (OfferStatus == 0) return 0;

        return getAuctionPrice((block.timestamp - AuctionStartTimestamp) / 60);
    }

    function getAuctionPrice(
        uint256 reduceTimes
    ) public view returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, OfferAcceptPrice * 10);
    }

    function getAuctionInfo() public view returns (NFTAuction memory auction) {
        auction.offerStatus = OfferStatus;
        auction.startTimestamp = AuctionStartTimestamp;
        auction.offerAcceptPrice = OfferAcceptPrice;
        auction.tokenId = AuctionTokenId;
        auction.currentPrice = getAuctionCurrentPrice();
    }

    function MT2VAmountRealtime(
        uint256 MTAmount,
        bool onReceived
    ) public view returns (uint256 VAmount) {
        if (totalSupply() == 0) {
            VAmount = MTBalanceRealtime();
        } else {
            VAmount =
                (totalSupply() * MTAmount) /
                MTBalanceRealtime() -
                (onReceived ? MTAmount : 0);
        }
    }

    function MT2VAmount(
        uint256 MTAmount,
        bool onReceived
    ) public view returns (uint256 VAmount) {
        uint256 balance = IMOPNToken(
            IMOPNGovernance(governance).tokenContract()
        ).balanceOf(address(this));
        if (totalSupply() == 0) {
            VAmount = balance;
        } else {
            VAmount =
                (totalSupply() * MTAmount) /
                (balance - (onReceived ? MTAmount : 0));
        }
    }

    function V2MTAmountRealtime(
        uint256 VAmount
    ) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = MTBalanceRealtime();
        } else {
            MTAmount = (MTBalanceRealtime() * VAmount) / totalSupply();
        }
    }

    function V2MTAmount(
        uint256 VAmount
    ) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = IMOPNToken(IMOPNGovernance(governance).tokenContract())
                .balanceOf(address(this));
        } else {
            MTAmount =
                (IMOPNToken(IMOPNGovernance(governance).tokenContract())
                    .balanceOf(address(this)) * VAmount) /
                totalSupply();
        }
    }

    function withdraw(uint256 amount) public {
        address collectionAddress_ = CollectionVaultLib.collectionAddress();
        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());
        mopn.claimCollectionMT(collectionAddress_);
        uint256 mtAmount = V2MTAmount(amount);
        require(mtAmount > 0, "zero to withdraw");
        IMOPNToken(IMOPNGovernance(governance).tokenContract()).transfer(
            msg.sender,
            mtAmount
        );
        _burn(msg.sender, amount);
        mopn.settleCollectionMOPNPoint(collectionAddress_);
        IMOPNGovernance(governance).changeTotalMTStaking(
            collectionAddress_,
            0,
            mtAmount
        );

        emit MTWithdraw(msg.sender, mtAmount, amount);
    }

    function getNFTOfferPrice() public view returns (uint256) {
        uint256 amount = MTBalanceRealtime();

        return
            (amount * IMOPNGovernance(governance).NFTOfferCoefficient()) /
            10 ** 15;
    }

    function MTBalanceRealtime() public view returns (uint256 amount) {
        amount =
            IMOPNData(IMOPNGovernance(governance).dataContract())
                .calcCollectionSettledMT(
                    CollectionVaultLib.collectionAddress()
                ) +
            IMOPNToken(IMOPNGovernance(governance).tokenContract()).balanceOf(
                address(this)
            );
    }

    function MTBalance() public view returns (uint256 balance) {
        balance = IMOPNToken(IMOPNGovernance(governance).tokenContract())
            .balanceOf(address(this));
    }

    function acceptNFTOffer(uint256 tokenId) public {
        require(OfferStatus == 0, "last offer auction not finish");
        address collectionAddress_ = CollectionVaultLib.collectionAddress();
        IERC721(collectionAddress_).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            "0x"
        );

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        mopn.claimCollectionMT(collectionAddress_);

        uint256 offerPrice = (IMOPNToken(
            IMOPNGovernance(governance).tokenContract()
        ).balanceOf(address(this)) *
            IMOPNGovernance(governance).NFTOfferCoefficient()) / 10 ** 15;

        IMOPNToken(IMOPNGovernance(governance).tokenContract()).transfer(
            msg.sender,
            offerPrice
        );

        AuctionTokenId = tokenId;
        OfferAcceptPrice = uint64(offerPrice);
        AuctionStartTimestamp = uint32(block.timestamp);
        OfferStatus = 1;

        mopn.settleCollectionMOPNPoint(collectionAddress_);
        IMOPNGovernance(governance).changeTotalMTStaking(
            collectionAddress_,
            0,
            offerPrice
        );

        IMOPNGovernance(governance).NFTOfferAccept(
            collectionAddress_,
            offerPrice
        );

        emit NFTOfferAccept(msg.sender, tokenId, offerPrice);
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public returns (bytes4) {
        require(
            msg.sender == IMOPNGovernance(governance).tokenContract(),
            "only accept mopn token"
        );

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        address collectionAddress_ = CollectionVaultLib.collectionAddress();

        if (bytes32(data) == keccak256("acceptAuctionBid")) {
            require(OfferStatus == 1, "auction not exist");

            require(
                block.timestamp >= AuctionStartTimestamp,
                "auction not start"
            );

            uint256 price = getAuctionCurrentPrice();
            require(value >= price, "MOPNToken not enough");

            if (value > price) {
                IMOPNToken(IMOPNGovernance(governance).tokenContract())
                    .transfer(from, value - price);
                value = price;
            }
            uint256 burnAmount;
            if (price > 0) {
                burnAmount = price / 20;
                IMOPNToken(IMOPNGovernance(governance).tokenContract()).burn(
                    burnAmount
                );

                price = price - burnAmount;
            }

            mopn.claimCollectionMT(collectionAddress_);
            mopn.settleCollectionMOPNPoint(collectionAddress_);
            IMOPNGovernance(governance).changeTotalMTStaking(
                collectionAddress_,
                1,
                price
            );

            IERC721(collectionAddress_).safeTransferFrom(
                address(this),
                from,
                AuctionTokenId,
                "0x"
            );

            emit NFTAuctionAccept(from, AuctionTokenId, price + burnAmount);

            OfferStatus = 0;
            AuctionTokenId = 0;
            AuctionStartTimestamp = 0;
            OfferAcceptPrice = 0;
        } else {
            require(OfferStatus == 0, "no staking during auction");
            mopn.claimCollectionMT(collectionAddress_);

            uint256 vtokenAmount = MT2VAmount(value, true);
            require(vtokenAmount > 0, "need more mt to get at least 1 vtoken");
            _mint(from, vtokenAmount);
            mopn.settleCollectionMOPNPoint(collectionAddress_);
            IMOPNGovernance(governance).changeTotalMTStaking(
                collectionAddress_,
                1,
                value
            );

            emit MTDeposit(from, value, vtokenAmount);
        }

        return IERC20Receiver.onERC20Received.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
