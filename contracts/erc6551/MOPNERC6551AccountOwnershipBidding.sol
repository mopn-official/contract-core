// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "../interfaces/IMOPN.sol";
import "../interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNERC6551Account.sol";
import "./interfaces/IERC6551Registry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract MOPNERC6551AccountOwnershipBidding is Ownable, ReentrancyGuard {
    uint256 public constant defaultCollectionLastBidBlock = 1;
    uint256 public constant defaultCollectionBidStartPrice = 10000000000000000;
    uint256 public constant minimalCollectionBidPrice = 1000000000000;

    IMOPNGovernance public immutable governance;

    event AccountRent(
        address indexed account,
        uint40 startblock,
        uint104 rent,
        address renter
    );

    event ClaimRent(address indexed account, uint104 claimed, address receiver);

    struct BidData {
        uint40 startBlock;
        uint104 rent;
        uint104 claimed;
    }

    /**
     * @notice collection Bid Data
     * @dev This includes the following data:
     * - uint40 lastBidBlock: bits 104-143
     * - uint104 lastBidPrice: bits 0-103
     */
    mapping(address => uint256) public collectionBidData;

    mapping(address => BidData) public bidsData;

    address public protocolFeeDestination;

    constructor(address governance_, address protocolFeeDestination_) {
        governance = IMOPNGovernance(governance_);
        protocolFeeDestination = protocolFeeDestination_;
    }

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function getBidData(address account) public view returns (BidData memory) {
        return bidsData[account];
    }

    function getQualifiedAccountCollection(
        address account
    ) public view returns (address) {
        (
            uint256 chainId,
            address collectionAddress,
            uint256 tokenId
        ) = IMOPNERC6551Account(payable(account)).token();

        require(chainId == block.chainid, "not support cross chain account");

        require(
            account ==
                IERC6551Registry(governance.ERC6551Registry()).account(
                    governance.ERC6551AccountProxy(),
                    chainId,
                    collectionAddress,
                    tokenId,
                    0
                ),
            "not a mopn Account Implementation"
        );

        return collectionAddress;
    }

    function bidNFTTo(
        address collectionAddress,
        uint256 tokenId,
        address to
    ) external payable returns (address account) {
        account = IERC6551Registry(governance.ERC6551Registry()).createAccount(
            governance.ERC6551AccountProxy(),
            block.chainid,
            collectionAddress,
            tokenId,
            0,
            ""
        );
        _bidAccount(account, collectionAddress, to);
    }

    function bidAccountTo(address account, address to) external payable {
        address collectionAddress = getQualifiedAccountCollection(account);
        _bidAccount(account, collectionAddress, to);
    }

    function _bidAccount(
        address account,
        address collectionAddress,
        address bidder
    ) internal {
        IMOPNERC6551Account a = IMOPNERC6551Account(payable(account));

        uint256 minimalPrice = getMinimalCollectionBidPrice(collectionAddress);
        collectionBidData[collectionAddress] =
            (block.number << 104) |
            ((minimalPrice * 105) / 100);

        uint256 accountMinimalPeriodPrice_ = getMinimalAccountBidPrice(account);
        if (accountMinimalPeriodPrice_ > minimalPrice) {
            minimalPrice = accountMinimalPeriodPrice_;
        }

        require(msg.value >= minimalPrice, "rent less than minimal price");

        cancelPreviousBid(account);

        BidData memory biddata;
        biddata.startBlock = uint40(block.number);
        biddata.rent = uint104(msg.value);

        bidsData[account] = biddata;

        a.ownerTransferTo(bidder, type(uint40).max);

        emit AccountRent(account, biddata.startBlock, biddata.rent, bidder);
    }

    function getMimimalBidPrice(
        address account,
        address collectionAddress
    ) public view returns (uint256 minimalPrice) {
        minimalPrice = getMinimalCollectionBidPrice(collectionAddress);
        uint256 accountMinimalPeriodPrice_ = getMinimalAccountBidPrice(account);
        if (accountMinimalPeriodPrice_ > minimalPrice) {
            minimalPrice = accountMinimalPeriodPrice_;
        }
    }

    function claimNFTOwnerIncome(address account) public nonReentrant {
        address nftowner = IMOPNERC6551Account(payable(account)).nftowner();
        require(msg.sender == nftowner, "not nft owner");
        uint256 nftownerincome = getSettledNFTOwnerIncome(account);
        if (nftownerincome > 0) {
            uint256 protocolFee = (nftownerincome * 5) / 100;
            (bool success1, ) = protocolFeeDestination.call{value: protocolFee}(
                ""
            );

            (bool success2, ) = nftowner.call{
                value: nftownerincome - protocolFee
            }("");
            require(success1 && success2, "Failed to transfer rent");

            bidsData[account].claimed += uint104(nftownerincome);

            emit ClaimRent(account, uint104(nftownerincome), nftowner);
        }
    }

    function cancelPreviousBid(address account) internal nonReentrant {
        IMOPNERC6551Account a = IMOPNERC6551Account(payable(account));
        address owner_ = a.owner();
        IMOPN(governance.mopnContract()).claimAccountMT(account, owner_);

        if (bidsData[account].startBlock > 0) {
            uint256 nftownerincome = getSettledNFTOwnerIncome(account);
            if (nftownerincome > 0) {
                uint256 protocolFee = (nftownerincome * 5) / 100;
                (bool success1, ) = protocolFeeDestination.call{
                    value: protocolFee
                }("");

                address nftowner = a.nftowner();
                (bool success2, ) = nftowner.call{
                    value: nftownerincome - protocolFee
                }("");
                require(success1 && success2, "Failed to transfer rent");

                bidsData[account].claimed += uint104(nftownerincome);

                emit ClaimRent(account, uint104(nftownerincome), nftowner);
            }

            uint256 ownerrefund = bidsData[account].rent -
                bidsData[account].claimed;
            if (ownerrefund > 0) {
                (bool success, ) = owner_.call{value: ownerrefund}("");
                require(success, "Failed to transfer rent refund");

                emit ClaimRent(account, uint104(ownerrefund), owner_);
            }
        }
    }

    function getSettledNFTOwnerIncome(
        address account
    ) public view returns (uint256 nftownerincome) {
        BidData memory bidData = bidsData[account];
        if (bidData.startBlock > 0) {
            if ((bidData.startBlock + 100000) < block.number) {
                nftownerincome =
                    bidData.rent -
                    ABDKMath64x64.mulu(
                        ABDKMath64x64.pow(
                            ABDKMath64x64.divu(99999, 100000),
                            block.number - bidData.startBlock - 100000
                        ),
                        bidData.rent / 2
                    );
            } else {
                nftownerincome =
                    (bidData.rent * (block.number - bidData.startBlock)) /
                    200000;
            }

            nftownerincome -= bidData.claimed;
        }
    }

    function getMinimalAccountBidPrice(
        address account
    ) public view returns (uint256 price) {
        BidData memory bidData = bidsData[account];
        if (bidData.startBlock > 0) {
            if ((bidData.startBlock + 100000) < block.number) {
                price = ABDKMath64x64.mulu(
                    ABDKMath64x64.pow(
                        ABDKMath64x64.divu(99999, 100000),
                        block.number - bidData.startBlock - 100000
                    ),
                    bidData.rent
                );
            } else {
                price = bidData.rent;
            }
            price = (price * 110) / 100;
        }
    }

    function getMinimalCollectionBidPrice(
        address collectionAddress
    ) public view returns (uint256 price) {
        uint256 bidStartPrice;
        uint256 lastBidBlock;
        if (collectionBidData[collectionAddress] == 0) {
            bidStartPrice = defaultCollectionBidStartPrice;
            lastBidBlock = defaultCollectionLastBidBlock;
        } else {
            bidStartPrice = uint104(collectionBidData[collectionAddress]);
            lastBidBlock = uint40(collectionBidData[collectionAddress] >> 104);
        }

        price = ABDKMath64x64.mulu(
            ABDKMath64x64.pow(
                ABDKMath64x64.divu(99, 100),
                (block.number - lastBidBlock) / 5
            ),
            bidStartPrice
        );
        if (price < minimalCollectionBidPrice) {
            price = minimalCollectionBidPrice;
        }
    }

    function cancelOwnershipBid() external {
        if (bidsData[msg.sender].startBlock > 0) {
            IMOPNERC6551Account a = IMOPNERC6551Account(payable(msg.sender));
            cancelPreviousBid(msg.sender);

            BidData memory biddata;
            bidsData[msg.sender] = biddata;

            a.ownerTransferTo(address(0), 0);

            emit AccountRent(
                msg.sender,
                biddata.startBlock,
                biddata.rent,
                address(0)
            );
        }
    }
}
