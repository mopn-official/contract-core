// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "./interfaces/IMOPNCollectionVault.sol";
import "./interfaces/IMOPN.sol";
import "./interfaces/IMOPNToken.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IERC20Receiver.sol";
import "./libraries/CollectionVaultLib.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract MOPNCollectionVault is
    IMOPNCollectionVault,
    ERC20,
    IERC20Receiver,
    IERC721Receiver,
    Ownable
{
    address public immutable governance;

    /**
     * @notice NFTOfferData
     * Bits Layouts:
     *  - [0..7] OfferStatus 0 offering 1 auctioning
     *  - [8..39] Auction Start Timestamp
     *  - [40..103] Offer Accept Price
     *  - [104..255] Auction tokenId
     */
    uint256 public NFTOfferData;

    constructor(address governance_) ERC20("MOPN VToken", "MVT") {
        governance = governance_;
    }

    function name() public view override returns (string memory) {
        return
            string(
                abi.encodePacked("MOPN VToken", " #", CollectionVaultLib.salt())
            );
    }

    function symbol() public pure override returns (string memory) {
        return "MVT";
    }

    function getOfferStatus() public view returns (uint256) {
        return uint8(NFTOfferData);
    }

    function getAuctionStartTimestamp() public view returns (uint256) {
        return uint32(NFTOfferData >> 8);
    }

    function getOfferAcceptPrice() public view returns (uint256) {
        return uint64(NFTOfferData >> 40);
    }

    function getAuctionTokenId() public view returns (uint256) {
        return NFTOfferData >> 104;
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

    function getAuctionInfo() public view returns (NFTAuction memory auction) {
        auction.offerStatus = getOfferStatus();
        auction.startTimestamp = getAuctionStartTimestamp();
        auction.offerAcceptPrice = getOfferAcceptPrice();
        auction.tokenId = getAuctionTokenId();
        auction.currentPrice = getAuctionCurrentPrice();
    }

    function MT2VAmount(
        uint256 MTAmount,
        bool onReceived
    ) public view returns (uint256 VAmount) {
        if (totalSupply() == 0) {
            VAmount = MTAmount * 10 ** 12;
        } else {
            VAmount =
                (totalSupply() * MTAmount) /
                (IMOPNToken(IMOPNGovernance(governance).mtContract()).balanceOf(
                    address(this)
                ) - (onReceived ? MTAmount : 0));
        }
    }

    function V2MTAmount(
        uint256 VAmount
    ) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = IMOPNToken(IMOPNGovernance(governance).mtContract())
                .balanceOf(address(this));
        } else {
            MTAmount =
                (IMOPNToken(IMOPNGovernance(governance).mtContract()).balanceOf(
                    address(this)
                ) * VAmount) /
                totalSupply();
        }
    }

    function withdraw(uint256 amount) public {
        address collectionAddress = CollectionVaultLib.collectionAddress();
        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());
        mopn.settleCollectionMining(collectionAddress);
        uint256 mtAmount = V2MTAmount(amount);
        require(mtAmount > 0, "zero to withdraw");
        IMOPNToken(IMOPNGovernance(governance).mtContract()).transfer(
            msg.sender,
            mtAmount
        );
        _burn(msg.sender, amount);
        mopn.settleCollectionMOPNPoint(collectionAddress);
        mopn.changeTotalMTStaking(
            collectionAddress,
            false,
            mtAmount,
            msg.sender
        );
    }

    function getNFTOfferPrice() public view returns (uint256) {
        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());
        uint256 amount = mopn.calcCollectionSettledMT(
            CollectionVaultLib.collectionAddress()
        ) +
            IMOPNToken(IMOPNGovernance(governance).mtContract()).balanceOf(
                address(this)
            );

        return (amount * mopn.NFTOfferCoefficient()) / 10 ** 18;
    }

    function MTBalance() public view returns (uint256 balance) {
        balance = IMOPNToken(IMOPNGovernance(governance).mtContract())
            .balanceOf(address(this));
        if (getOfferStatus() == 1) {
            balance += getOfferAcceptPrice();
        }
    }

    function acceptNFTOffer(uint256 tokenId) public {
        require(getOfferStatus() == 0, "last offer auction not finish");
        address collectionAddress = CollectionVaultLib.collectionAddress();
        IERC721(collectionAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            "0x"
        );

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        mopn.settleCollectionMining(collectionAddress);

        uint256 offerPrice = (IMOPNToken(
            IMOPNGovernance(governance).mtContract()
        ).balanceOf(address(this)) * mopn.NFTOfferCoefficient()) / 10 ** 18;

        IMOPNToken(IMOPNGovernance(governance).mtContract()).transfer(
            msg.sender,
            offerPrice
        );

        NFTOfferData =
            (tokenId << 104) |
            (offerPrice << 40) |
            (block.timestamp << 8) |
            uint256(1);

        mopn.settleCollectionMOPNPoint(collectionAddress);
        mopn.NFTOfferAcceptNotify(collectionAddress, offerPrice, tokenId);
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public returns (bytes4) {
        require(
            msg.sender == IMOPNGovernance(governance).mtContract(),
            "only accept mopn token"
        );

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        address collectionAddress = CollectionVaultLib.collectionAddress();

        if (bytes32(data) == keccak256("acceptAuctionBid")) {
            require(getOfferStatus() == 1, "auction not exist");

            uint256 startTimestamp = getAuctionStartTimestamp();
            require(block.timestamp >= startTimestamp, "auction not start");

            uint256 price = getAuctionCurrentPrice();

            require(value >= price, "MOPNToken not enough");

            if (value > price) {
                IMOPNToken(IMOPNGovernance(governance).mtContract()).transfer(
                    from,
                    value - price
                );
                value = price;
            }
            if (price > 0) {
                uint256 burnAmount = (price * 2) / 10;
                IMOPNToken(IMOPNGovernance(governance).mtContract()).burn(
                    burnAmount
                );

                price = price - burnAmount;
            }

            mopn.settleCollectionMining(collectionAddress);
            mopn.settleCollectionMOPNPoint(collectionAddress);
            uint256 offerAcceptPrice = getOfferAcceptPrice();
            if (price > offerAcceptPrice) {
                mopn.changeTotalMTStaking(
                    collectionAddress,
                    true,
                    price - offerAcceptPrice,
                    address(0)
                );
            } else if (price < offerAcceptPrice) {
                mopn.changeTotalMTStaking(
                    collectionAddress,
                    false,
                    offerAcceptPrice - price,
                    address(0)
                );
            }

            IERC721(collectionAddress).safeTransferFrom(
                address(this),
                from,
                getAuctionTokenId(),
                "0x"
            );
            mopn.NFTAuctionAcceptNotify(
                collectionAddress,
                value,
                getAuctionTokenId()
            );
            NFTOfferData = 0;
        } else {
            mopn.settleCollectionMining(collectionAddress);

            uint256 vtokenAmount = MT2VAmount(value, true);
            _mint(from, vtokenAmount);
            mopn.settleCollectionMOPNPoint(collectionAddress);
            mopn.changeTotalMTStaking(collectionAddress, true, value, from);
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
