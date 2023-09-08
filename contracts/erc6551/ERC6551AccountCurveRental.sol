// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IMOPN.sol";
import "../interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPNERC6551Account.sol";
import "./interfaces/IERC6551AccountOwnerHosting.sol";
import "./interfaces/IERC6551Registry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ERC6551AccountCurveRental is
    IERC6551AccountOwnerHosting,
    Ownable,
    ReentrancyGuard
{
    struct RentData {
        uint256 endBlock;
        uint256 rent;
        address renter;
    }

    mapping(address => RentData) public rentsData;

    uint256 public immutable rentGap;

    IMOPNGovernance public immutable governance;

    constructor(address governance_, uint256 rentGap_) {
        governance = IMOPNGovernance(governance_);
        rentGap = rentGap_;
    }

    function getRentData(
        address account
    ) public view returns (RentData memory) {
        return rentsData[account];
    }

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        return
            IERC6551Registry(governance.ERC6551Registry()).createAccount(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt,
                initData
            );
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
        uint256 tokenId
    ) external payable nonReentrant {
        address account = IERC6551Registry(governance.ERC6551Registry())
            .createAccount(
                governance.ERC6551AccountProxy(),
                block.chainid,
                collectionAddress,
                tokenId,
                0,
                ""
            );
        require(
            IMOPNERC6551Account(payable(account)).ownerHosting() ==
                address(this),
            "account owner hosting mismatch"
        );
        uint256 reserveRent = collectionRentCurve(collectionAddress);
        if (reserveRent > 0) {
            reserveRent--;
        }

        RentData memory rentData = rentsData[account];
        if (rentData.endBlock > block.number) {
            if (rentData.rent > reserveRent) {
                reserveRent = rentData.rent;
                if (rentData.renter == msg.sender) {
                    reserveRent--;
                }
            }
        }

        require(msg.value > reserveRent, "rent less than reserve rent");

        IMOPN(governance.mopnContract()).claimAccountMT(account, address(0));
        _settlePreviousRent(account);

        rentsData[account].endBlock = block.number + rentGap;
        rentsData[account].rent = msg.value;
        rentsData[account].renter = msg.sender;
        IMOPNERC6551Account(payable(account)).hostingOwnerTransferNotify(
            msg.sender,
            rentsData[account].endBlock
        );
    }

    function rentAccount(address account) external payable nonReentrant {
        require(
            IMOPNERC6551Account(payable(account)).ownerHosting() ==
                address(this),
            "account owner hosting mismatch"
        );
        address collectionAddress = getQualifiedAccountCollection(account);
        uint256 reserveRent = collectionRentCurve(collectionAddress);
        if (reserveRent > 0) {
            reserveRent--;
        }

        RentData memory rentData = rentsData[account];
        if (rentData.endBlock > block.number) {
            if (rentData.rent > reserveRent) {
                reserveRent = rentData.rent;
                if (rentData.renter == msg.sender) {
                    reserveRent--;
                }
            }
        }

        require(msg.value > reserveRent, "rent less than reserve rent");

        IMOPN(governance.mopnContract()).claimAccountMT(account, address(0));
        _settlePreviousRent(account);

        rentsData[account].endBlock = block.number + rentGap;
        rentsData[account].rent = msg.value;
        rentsData[account].renter = msg.sender;
        IMOPNERC6551Account(payable(account)).hostingOwnerTransferNotify(
            msg.sender,
            rentsData[account].endBlock
        );
    }

    function _settlePreviousRent(address account) internal {
        RentData memory rentData = rentsData[account];
        if (rentData.rent > 0) {
            uint256 excessPayment;
            bool success;
            if (rentData.endBlock > block.number) {
                excessPayment =
                    (rentData.rent * (rentData.endBlock - block.number)) /
                    rentGap;
                (success, ) = rentData.renter.call{value: excessPayment}("");
                require(success, "Failed to refund excess payment");
            }

            address nftowner = IMOPNERC6551Account(payable(account)).nftowner();
            (success, ) = nftowner.call{value: rentData.rent - excessPayment}(
                ""
            );
            require(success, "Failed to transfer rent");

            rentsData[account].rent = 0;
            rentsData[account].endBlock = 0;
            rentsData[account].renter = address(0);
        }
    }

    function claimRent(address account) public nonReentrant {
        require(rentsData[account].endBlock > 0, "nothing to claim");
        require(
            rentsData[account].endBlock < block.number,
            "curve rent not finish"
        );
        _settlePreviousRent(account);
    }

    function collectionRentCurve(
        address collectionAddress
    ) public view returns (uint256) {
        return 1;
    }

    function owner(
        address account
    ) external view override returns (address owner_) {
        if (rentsData[account].endBlock > block.number) {
            owner_ = rentsData[account].renter;
        }
    }

    function beforeRevokeHosting() external nonReentrant {
        if (rentsData[msg.sender].endBlock < block.number) {
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
