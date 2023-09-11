// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "../interfaces/IMOPN.sol";
import "../interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNERC6551Account.sol";
import "./interfaces/IERC6551AccountOwnerHosting.sol";
import "./interfaces/IERC6551Registry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract ERC6551AccountCurveRental is
    IERC6551AccountOwnerHosting,
    Ownable,
    ReentrancyGuard
{
    uint256 public constant defaultLastRentBlock = 1;
    uint256 public constant defaultRentPeriodPrice = 100000000000000000;
    uint256 public constant minimalRentPeriodPrice = 100000000000000;
    uint256 public constant minimalRentPeriod = 100000;

    IMOPNGovernance public immutable governance;

    event AccountRent(
        address indexed account,
        uint32 rentRange,
        uint96 rent,
        address renter
    );

    event ClaimRent(
        address indexed account,
        uint32 rentRange,
        uint96 claimed,
        address owner
    );

    struct RentData {
        uint32 endBlock;
        uint32 rentRange;
        uint96 rent;
        uint96 claimed;
        address renter;
    }

    /**
     * @notice collection Curve Data
     * @dev This includes the following data:
     * - uint32 lastRentBlock: bits 96-127
     * - uint96 lastRentPrice: bits 0-95
     */
    mapping(address => uint256) public collectionCurveData;

    mapping(address => RentData) public rentsData;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function getRentData(
        address account
    ) public view returns (RentData memory) {
        return rentsData[account];
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

    function rentNFT(
        address collectionAddress,
        uint256 tokenId,
        uint32 rentRange
    ) external payable {
        address account = IERC6551Registry(governance.ERC6551Registry())
            .createAccount(
                governance.ERC6551AccountProxy(),
                block.chainid,
                collectionAddress,
                tokenId,
                0,
                ""
            );
        _rentAccount(account, collectionAddress, rentRange);
    }

    function rentAccount(address account, uint32 rentRange) external payable {
        address collectionAddress = getQualifiedAccountCollection(account);
        _rentAccount(account, collectionAddress, rentRange);
    }

    function _rentAccount(
        address account,
        address collectionAddress,
        uint32 rentRange
    ) internal {
        IMOPNERC6551Account a = IMOPNERC6551Account(payable(account));
        require(
            a.ownerHosting() == address(this),
            "account owner hosting mismatch"
        );
        require(rentRange >= minimalRentPeriod, "rent range too small");
        uint256 minimalPrice = minimalCurveRentPeriodPrice(collectionAddress);
        collectionCurveData[collectionAddress] =
            (block.number << 96) |
            ((minimalPrice * 110) / 100);

        uint256 accountMinimalPeriodPrice_ = accountMinimalPeriodPrice(account);
        if (accountMinimalPeriodPrice_ > minimalPrice) {
            minimalPrice = accountMinimalPeriodPrice_;
        }
        minimalPrice = (minimalPrice * rentRange) / 100000;
        require(msg.value >= minimalPrice, "rent less than reserve rent");

        IMOPN(governance.mopnContract()).claimAccountMT(account, a.owner());
        _settlePreviousRent(account);

        rentsData[account].endBlock = uint32(block.number) + rentRange;
        rentsData[account].rentRange = rentRange;
        rentsData[account].rent = uint96(msg.value);
        rentsData[account].renter = msg.sender;
        a.hostingOwnerTransferNotify(msg.sender, rentsData[account].endBlock);

        emit AccountRent(
            account,
            rentRange,
            rentsData[account].rent,
            msg.sender
        );
    }

    function _settlePreviousRent(address account) internal nonReentrant {
        RentData memory rentData = rentsData[account];
        if (rentData.rentRange > 0) {
            uint256 excessPayment;
            bool success;
            if (rentData.endBlock > block.number) {
                excessPayment =
                    ((rentData.rent - rentData.claimed) *
                        (rentData.endBlock - block.number)) /
                    rentData.rentRange;
                (success, ) = rentData.renter.call{value: excessPayment}("");
                require(success, "Failed to refund excess payment");

                emit ClaimRent(
                    account,
                    0,
                    uint96(excessPayment),
                    rentData.renter
                );
            }

            address nftowner = IMOPNERC6551Account(payable(account)).nftowner();
            (success, ) = nftowner.call{
                value: rentData.rent - rentData.claimed - excessPayment
            }("");
            require(success, "Failed to transfer rent");

            emit ClaimRent(
                account,
                0,
                uint96(rentData.rent - rentData.claimed - excessPayment),
                nftowner
            );

            RentData memory emptydata;
            rentsData[account] = emptydata;
        }
    }

    function claimRent(address account) public {
        require(rentsData[account].endBlock > 0, "nothing to claim");
        if (rentsData[account].endBlock <= block.number) {
            _settlePreviousRent(account);
        } else {
            uint96 unclaimed = uint96(unclaimedRent(account));
            if (unclaimed > 0) {
                address nftowner = IMOPNERC6551Account(payable(account))
                    .nftowner();
                (bool success, ) = nftowner.call{value: unclaimed}("");
                require(success, "Failed to transfer rent");
                rentsData[account].claimed += unclaimed;
                rentsData[account].rentRange =
                    rentsData[account].endBlock -
                    uint32(block.number);
                emit ClaimRent(
                    account,
                    rentsData[account].rentRange,
                    unclaimed,
                    nftowner
                );
            }
        }
    }

    function unclaimedRent(address account) public view returns (uint256 rent) {
        RentData memory rentData = rentsData[account];
        if (block.number > (rentData.endBlock - rentData.rentRange)) {
            if (block.number > rentData.endBlock) {
                rent = rentData.rent - rentData.claimed;
            } else {
                rent =
                    ((rentData.rent - rentData.claimed) *
                        (block.number -
                            (rentData.endBlock - rentData.rentRange))) /
                    rentData.rentRange;
            }
        }
    }

    function nonExecuteRent(
        address account
    ) public view returns (uint256 rent) {
        RentData memory rentData = rentsData[account];
        if (block.number < rentData.endBlock) {
            rent = rentData.rent - rentData.claimed - unclaimedRent(account);
        }
    }

    function accountMinimalPeriodPrice(
        address account
    ) public view returns (uint256 price) {
        RentData memory rentData = rentsData[account];
        if (block.number < rentData.endBlock) {
            price =
                ((rentData.rent / rentData.rentRange) *
                    minimalRentPeriod *
                    110) /
                100;
        }
    }

    function minimalCurveRentPeriodPrice(
        address collectionAddress
    ) public view returns (uint256 price) {
        uint256 lastRentPeriodPrice;
        uint256 lastRentBlock;
        if (collectionCurveData[collectionAddress] == 0) {
            lastRentPeriodPrice = defaultRentPeriodPrice;
            lastRentBlock = defaultLastRentBlock;
        } else {
            lastRentPeriodPrice = uint96(
                collectionCurveData[collectionAddress]
            );
            lastRentBlock = uint32(
                collectionCurveData[collectionAddress] >> 96
            );
        }

        price = ABDKMath64x64.mulu(
            ABDKMath64x64.pow(
                ABDKMath64x64.divu(99, 100),
                (block.number - lastRentBlock) / 5
            ),
            lastRentPeriodPrice
        );
        if (price < minimalRentPeriodPrice) {
            price = minimalRentPeriodPrice;
        }
    }

    function owner(
        address account
    ) external view override returns (address owner_) {
        if (rentsData[account].endBlock > block.number) {
            owner_ = rentsData[account].renter;
        }
    }

    function beforeRevokeHosting() external {
        if (rentsData[msg.sender].rent > 0) {
            address owner_ = IMOPNERC6551Account(payable(msg.sender)).owner();
            IMOPN(governance.mopnContract()).claimAccountMT(msg.sender, owner_);
            _settlePreviousRent(msg.sender);
            IMOPNERC6551Account(payable(msg.sender)).hostingOwnerTransferNotify(
                    owner_,
                    block.number
                );
        }
    }

    function revokeHostingLockState(address) external pure returns (bool) {
        return false;
    }
}
