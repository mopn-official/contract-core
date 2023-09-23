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
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MOPNERC6551AccountOwnershipBidding is
    Ownable,
    ReentrancyGuard,
    Multicall
{
    uint256 public immutable defaultCollectionLastBidBlock;
    uint256 public constant defaultCollectionBidStartPrice = 10000000000000000;
    uint256 public constant minimalCollectionBidPrice = 1000000000000;

    IMOPNGovernance public immutable governance;

    IERC6551Registry public immutable erc6551registry;

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

    constructor(
        address governance_,
        address erc6551registry_,
        address protocolFeeDestination_,
        uint256 defaultCollectionLastBidBlock_
    ) {
        governance = IMOPNGovernance(governance_);
        erc6551registry = IERC6551Registry(erc6551registry_);
        protocolFeeDestination = protocolFeeDestination_;
        defaultCollectionLastBidBlock = defaultCollectionLastBidBlock_;
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
                erc6551registry.account(
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
        account = erc6551registry.createAccount(
            governance.ERC6551AccountProxy(),
            block.chainid,
            collectionAddress,
            tokenId,
            0,
            ""
        );
        _bidAccountTo(account, collectionAddress, to);
    }

    function bidAccountTo(address account, address to) public payable {
        address collectionAddress = getQualifiedAccountCollection(account);
        _bidAccountTo(account, collectionAddress, to);
    }

    function _bidAccountTo(
        address account,
        address collectionAddress,
        address to
    ) internal {
        uint256 collectionMinimalPrice = getMinimalCollectionBidPrice(
            collectionAddress
        );

        uint256 accountMinimalPeriodPrice_ = getMinimalAccountBidPrice(account);
        if (accountMinimalPeriodPrice_ > collectionMinimalPrice) {
            require(
                msg.value >= accountMinimalPeriodPrice_,
                "rent less than minimal price"
            );
        } else {
            require(
                msg.value >= collectionMinimalPrice,
                "rent less than minimal price"
            );
        }

        _bidAccount(account, to, msg.value);

        collectionBidData[collectionAddress] =
            (block.number << 104) |
            ((collectionMinimalPrice * 102) / 100);
    }

    function bidNFTsTo(
        address[] memory collectionAddresses,
        uint256[][] memory tokenIds,
        uint256[] memory prices,
        address to
    ) public payable {
        uint256 totalprice;
        uint256 i;
        for (i = 0; i < prices.length; i++) {
            totalprice += prices[i];
        }
        require(msg.value >= totalprice, "total rent less than prices");
        i = 0;
        for (uint256 k = 0; k < collectionAddresses.length; k++) {
            uint256 collectionMinimalPrice = getMinimalCollectionBidPrice(
                collectionAddresses[k]
            );
            for (uint256 j = 0; j < tokenIds[k].length; j++) {
                address account = erc6551registry.createAccount(
                    governance.ERC6551AccountProxy(),
                    block.chainid,
                    collectionAddresses[k],
                    tokenIds[k][j],
                    0,
                    ""
                );
                uint256 accountMinimalPeriodPrice_ = getMinimalAccountBidPrice(
                    account
                );
                if (accountMinimalPeriodPrice_ > collectionMinimalPrice) {
                    require(
                        prices[i] >= accountMinimalPeriodPrice_,
                        "rent less than minimal price"
                    );
                } else {
                    require(
                        prices[i] >= collectionMinimalPrice,
                        "rent less than minimal price"
                    );
                }

                _bidAccount(account, to, prices[i]);

                i++;
                collectionMinimalPrice = (collectionMinimalPrice * 102) / 100;
            }

            collectionBidData[collectionAddresses[k]] =
                (block.number << 104) |
                collectionMinimalPrice;
        }
        if (msg.value > totalprice) {
            (bool success, ) = msg.sender.call{value: msg.value - totalprice}(
                ""
            );
            require(success, "Failed to transfer extra rent");
        }
    }

    function _bidAccount(
        address account,
        address bidder,
        uint256 price
    ) internal {
        cancelPreviousBid(account);

        BidData memory biddata;
        biddata.startBlock = uint40(block.number);
        biddata.rent = uint104(price);

        bidsData[account] = biddata;

        IMOPNERC6551Account(payable(account)).ownerTransferTo(
            bidder,
            type(uint40).max
        );

        emit AccountRent(account, biddata.startBlock, biddata.rent, bidder);
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
            if ((bidData.startBlock + 200000) < block.number) {
                nftownerincome =
                    bidData.rent -
                    ABDKMath64x64.mulu(
                        ABDKMath64x64.pow(
                            ABDKMath64x64.divu(199999, 200000),
                            block.number - bidData.startBlock - 200000
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

    function getMinimalAccountBidPrice(
        address account
    ) public view returns (uint256 price) {
        BidData memory bidData = bidsData[account];
        if (bidData.startBlock > 0) {
            if ((bidData.startBlock + 200000) < block.number) {
                price = ABDKMath64x64.mulu(
                    ABDKMath64x64.pow(
                        ABDKMath64x64.divu(199999, 200000),
                        block.number - bidData.startBlock - 200000
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
        uint256 lastBidBlock;
        if (collectionBidData[collectionAddress] == 0) {
            price = defaultCollectionBidStartPrice;
            lastBidBlock = defaultCollectionLastBidBlock;
        } else {
            price = uint104(collectionBidData[collectionAddress]);
            lastBidBlock = uint40(collectionBidData[collectionAddress] >> 104);
        }

        if (block.number > lastBidBlock) {
            price = ABDKMath64x64.mulu(
                ABDKMath64x64.pow(
                    ABDKMath64x64.divu(99, 100),
                    (block.number - lastBidBlock) / 5
                ),
                price
            );
        }

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
