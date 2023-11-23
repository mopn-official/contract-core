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
    uint48 public constant MaxBidCoefficient = 100000;
    uint48 public constant MinBidCoefficient = 1;

    uint8 public VaultStatus;
    uint32 public AskStartBlock;
    uint64 public BidAcceptPrice;
    uint48 public BidCoefficient;
    uint32 public BidStartBlock;
    uint256 public BidAcceptTokenId;

    constructor(address governance_) ERC20("MOPN VToken", "MVT") {
        governance = governance_;
    }

    function name() public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    super.name(),
                    " #",
                    Strings.toString(
                        IMOPNGovernance(governance).getCollectionVaultIndex(
                            collectionAddress()
                        )
                    )
                )
            );
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function collectionAddress() public view returns (address) {
        return CollectionVaultLib.collectionAddress();
    }

    function getBidCoefficient() public view returns (uint48 BidCoefficient_) {
        BidCoefficient_ = BidCoefficient;
        if (BidCoefficient_ == 0) {
            BidCoefficient_ = MaxBidCoefficient;
        }
        if (VaultStatus == 0) {
            BidCoefficient_ = uint48(
                ABDKMath64x64.mulu(
                    ABDKMath64x64.pow(
                        ABDKMath64x64.divu(101, 100),
                        (block.number - BidStartBlock) / 7200
                    ),
                    BidCoefficient_
                )
            );
            if (BidCoefficient_ > MaxBidCoefficient) {
                BidCoefficient_ = MaxBidCoefficient;
            }
        }
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getAskCurrentPrice() public view returns (uint256) {
        if (VaultStatus == 0) return 0;

        return getAskPrice((block.number - AskStartBlock) / 60);
    }

    function getAskPrice(uint256 reduceTimes) public view returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, (BidAcceptPrice * 12) / 10);
    }

    function getAskInfo() public view returns (AskStruct memory auction) {
        auction.vaultStatus = VaultStatus;
        auction.startBlock = AskStartBlock;
        auction.bidAcceptPrice = BidAcceptPrice;
        auction.tokenId = BidAcceptTokenId;
        auction.currentPrice = getAskCurrentPrice();
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

        emit MTWithdraw(msg.sender, mtAmount, amount);
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

    function getBidPrice() public view returns (uint256) {
        uint256 amount = MTBalanceRealtime();
        return (amount * getBidCoefficient()) / 1000000;
    }

    function getBidInfo() public view returns (BidStruct memory bid) {
        bid.vaultStatus = VaultStatus;
        bid.startBlock = AskStartBlock;
        bid.Coefficient = getBidCoefficient();
    }

    function acceptBid(uint256 tokenId) public {
        require(VaultStatus == 0, "last ask not finish");
        address collectionAddress_ = CollectionVaultLib.collectionAddress();
        IERC721(collectionAddress_).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            "0x"
        );

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        mopn.claimCollectionMT(collectionAddress_);

        BidCoefficient = getBidCoefficient();
        uint256 offerPrice = (IMOPNToken(
            IMOPNGovernance(governance).tokenContract()
        ).balanceOf(address(this)) * BidCoefficient) / 1000000;

        IMOPNToken(IMOPNGovernance(governance).tokenContract()).transfer(
            msg.sender,
            offerPrice
        );

        BidAcceptTokenId = tokenId;
        BidAcceptPrice = uint64(offerPrice);
        AskStartBlock = uint32(block.number);
        VaultStatus = 1;

        BidCoefficient = (BidCoefficient * 98) / 100;
        if (BidCoefficient < MinBidCoefficient) {
            BidCoefficient = MinBidCoefficient;
        }

        mopn.settleCollectionMOPNPoint(collectionAddress_);

        emit BidAccept(msg.sender, tokenId, offerPrice);
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

        if (bytes32(data) == keccak256("acceptAsk")) {
            require(VaultStatus == 1, "ask not exist");

            require(block.number >= AskStartBlock, "ask not start");

            uint256 price = getAskCurrentPrice();
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

            IERC721(collectionAddress_).safeTransferFrom(
                address(this),
                from,
                BidAcceptTokenId,
                "0x"
            );

            emit AskAccept(from, BidAcceptTokenId, price + burnAmount);

            VaultStatus = 0;
            BidAcceptTokenId = 0;
            AskStartBlock = 0;
            BidAcceptPrice = 0;
            BidStartBlock = uint32(block.number);
        } else {
            require(VaultStatus == 0, "no staking during ask");
            mopn.claimCollectionMT(collectionAddress_);

            uint256 vtokenAmount = MT2VAmount(value, true);
            require(vtokenAmount > 0, "need more mt to get at least 1 vtoken");
            _mint(from, vtokenAmount);
            mopn.settleCollectionMOPNPoint(collectionAddress_);

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
