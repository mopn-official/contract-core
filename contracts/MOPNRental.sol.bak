// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./erc6551/interfaces/IMOPNERC6551Account.sol";
import "./erc6551/interfaces/IERC6551Registry.sol";

contract MOPNRental is EIP712, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable offerToken;
    uint256 public constant MAX_RENT_DURATION = 31536000;

    struct Order {
        uint8 orderType;
        uint256 orderId;
        address owner;
        address nftToken;
        address implementation;
        address account;
        uint256 quantity;
        uint256 price;
        uint256 minDuration;
        uint256 maxDuration;
        uint256 expiry;
        uint256 feeRate; // 25 / 1000
        address feeReceiver;
        uint256 salt;
    }

    struct OrderStatus {
        uint8 orderType;
        uint256 orderId;
        bool isValidated;
        bool isCanceled;
        uint256 numerator;
        uint256 denominator;
    }

    mapping(uint256 => OrderStatus) public orderStatus;

    IERC6551Registry public immutable ERC6551Registry;

    event OrderPaid(
        uint256 indexed orderId,
        address indexed sender,
        uint256 amount,
        uint256 duration,
        uint40 endBlock,
        address[] accounts,
        OrderStatus orderStatus
    );

    event OrderStatusChanged(
        uint256 indexed orderId,
        uint256 indexed orderIdHash,
        OrderStatus orderStatus
    );

    event FeeWithdrawed(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    bytes32 orderTypeHash =
        keccak256(
            "Order(uint8 orderType,uint256 orderId,address owner,address nftToken,address implementation,address account,uint256 quantity,uint256 price,uint256 minDuration,uint256 maxDuration,uint256 expiry,uint256 feeRate,address feeReceiver,uint256 salt)"
        );

    modifier validOrder(
        Order calldata order,
        uint256 duration,
        bytes memory signature
    ) {
        require(
            verifyOrderSignature(order, signature),
            "INVALID_ORDER_SIGNATURE"
        );
        require(order.expiry > block.timestamp, "ORDER_EXPIRED");
        require(
            order.orderType == 0 || order.orderType == 1,
            "INVALID_ORDER_TYPE"
        );
        require(
            duration <= MAX_RENT_DURATION &&
                duration >= order.minDuration &&
                duration <= order.maxDuration,
            "INVALID_DURATION"
        );

        if (order.orderType == 0) {
            require(
                orderStatus[_orderIdHash(order.owner, order.orderId)].orderId ==
                    0,
                "ORDER_EXECUTED"
            );
        } else {
            require(
                orderStatus[_orderIdHash(order.owner, order.orderId)].orderId ==
                    0 ||
                    orderStatus[_orderIdHash(order.owner, order.orderId)]
                        .isValidated,
                "INVALID_ORDER_STATUS"
            );
        }
        _;
    }

    constructor(
        address offerToken_,
        address ERC6551Registry_
    ) EIP712("MOPNRental", "1") {
        offerToken = IERC20(offerToken_);
        ERC6551Registry = IERC6551Registry(ERC6551Registry_);
    }

    function rentFromList(
        Order calldata list,
        uint256 duration,
        bytes memory signature
    ) external payable nonReentrant validOrder(list, duration, signature) {
        require(msg.sender != list.owner, "INVALID_ORDER_OWNER");
        require(list.quantity == 1, "QUANTITY_MISMATCH");
        require(
            list.price.mul(duration) == msg.value,
            "INCORRECT_PAYMENT_AMOUNT"
        );

        // account rentExecute
        IMOPNERC6551Account account = IMOPNERC6551Account(
            payable(list.account)
        );
        _validAccount(account, list);

        require(account.isOwner(list.owner), "ACCOUNT_OWNER_MISMATCH");

        uint256 orderIdHash = _orderIdHash(list.owner, list.orderId);
        _updateOrderStatus(orderIdHash, 0, true, false, 1, 1);

        uint40 endBlock = uint40(block.number.add(duration.div(12)));
        account.ownerTransferTo(msg.sender, endBlock);

        // transfer fee and amount
        uint256 fee;
        uint256 amount = msg.value;
        bool success;

        if (list.feeRate > 0 && list.feeReceiver != address(0)) {
            fee = msg.value.mul(list.feeRate).div(1000);
            amount = msg.value.sub(fee);
            if (list.feeReceiver != address(this)) {
                (success, ) = payable(list.feeReceiver).call{value: fee}("");
                require(success, "TRANSFER_FAILED");
            }
        }

        (success, ) = payable(list.owner).call{value: amount}("");
        require(success, "TRANSFER_FAILED");

        address[] memory accounts = new address[](1);
        accounts[0] = list.account;

        emit OrderPaid(
            list.orderId,
            msg.sender,
            msg.value,
            duration,
            endBlock,
            accounts,
            orderStatus[orderIdHash]
        );
    }

    function acceptOffer(
        Order calldata offer,
        uint256 duration,
        address[] calldata accounts,
        uint256 offerAmount,
        bytes memory signature
    ) external nonReentrant validOrder(offer, duration, signature) {
        uint256 orderIdHash = _orderIdHash(offer.owner, offer.orderId);

        if (orderStatus[orderIdHash].isValidated) {
            require(
                orderStatus[orderIdHash].numerator.add(accounts.length) <=
                    orderStatus[orderIdHash].denominator,
                "INVALID_ORDER_STATUS"
            );
        }

        require(msg.sender != offer.owner, "INVALID_ORDER_OWNER");
        require(
            accounts.length > 0 &&
                offer.quantity > 0 &&
                accounts.length <= offer.quantity,
            "QUANTITY_MISMATCH"
        );
        require(
            offer.price.mul(duration).mul(accounts.length) == offerAmount,
            "INCORRECT_PAYMENT_AMOUNT"
        );
        require(
            offerToken.balanceOf(offer.owner) >= offerAmount,
            "INSUFFICIENT_OFFER_TOKEN_BALANCE"
        );
        require(
            offerToken.allowance(offer.owner, address(this)) >= offerAmount,
            "INSUFFICIENT_OFFER_TOKEN_ALLOWANCE"
        );

        _updateOrderStatus(
            orderIdHash,
            1,
            true,
            false,
            orderStatus[orderIdHash].numerator.add(accounts.length),
            offer.quantity
        );

        uint40 endBlock = uint40(block.number.add(duration.div(12)));

        _processOfferAccounts(offer, accounts, endBlock);

        // transfer fee and amount
        _handleOfferTransfers(offer, offerAmount);

        emit OrderPaid(
            offer.orderId,
            msg.sender,
            offerAmount,
            duration,
            endBlock,
            accounts,
            orderStatus[orderIdHash]
        );
    }

    function cancelOrder(
        Order calldata order,
        bytes memory signature
    ) external validOrder(order, 0, signature) {
        require(order.owner == msg.sender, "INVALID_ORDER_OWNER");

        uint256 orderIdHash = _orderIdHash(order.owner, order.orderId);
        require(orderStatus[orderIdHash].orderId == 0, "ORDER_EXECUTED");

        _updateOrderStatus(orderIdHash, order.orderType, false, true, 0, 0);
    }

    function _processOfferAccounts(
        Order calldata offer,
        address[] calldata accounts,
        uint40 endBlock
    ) private {
        for (uint256 i = 0; i < accounts.length; i++) {
            IMOPNERC6551Account account = IMOPNERC6551Account(
                payable(accounts[i])
            );
            _validAccount(account, offer);

            require(
                account.isOwner(msg.sender) || address(account) == msg.sender,
                "ACCOUNT_OWNER_MISMATCH"
            );

            account.ownerTransferTo(offer.owner, endBlock);
        }
    }

    // Handle token transfers
    function _handleOfferTransfers(
        Order calldata offer,
        uint256 offerAmount
    ) private {
        uint256 amount = offerAmount;
        uint256 fee;

        if (offer.feeRate > 0 && offer.feeReceiver != address(0)) {
            fee = offerAmount.mul(offer.feeRate).div(1000);
            amount = offerAmount.sub(fee);
            offerToken.safeTransferFrom(offer.owner, offer.feeReceiver, fee);
        }

        offerToken.safeTransferFrom(offer.owner, msg.sender, amount);
    }

    function _orderIdHash(
        address owner,
        uint256 orderId
    ) private pure returns (uint256 hashId) {
        hashId = (orderId << 160) | uint256(uint160(owner));
    }

    function _hashOrder(
        Order calldata order
    ) private view returns (bytes32 hash) {
        return
            _hashTypedDataV4(
                keccak256(
                    bytes.concat(
                        abi.encode(
                            orderTypeHash,
                            order.orderType,
                            order.orderId,
                            order.owner,
                            order.nftToken,
                            order.implementation,
                            order.account
                        ),
                        abi.encode(
                            order.quantity,
                            order.price,
                            order.minDuration,
                            order.maxDuration,
                            order.expiry,
                            order.feeRate,
                            order.feeReceiver,
                            order.salt
                        )
                    )
                )
            );
    }

    function verifyOrderSignature(
        Order calldata order,
        bytes memory signature
    ) public view returns (bool) {
        return order.owner == ECDSA.recover(_hashOrder(order), signature);
    }

    function _updateOrderStatus(
        uint256 orderIdHash,
        uint8 orderType,
        bool isValidated,
        bool isCanceled,
        uint256 numerator,
        uint256 denominator
    ) private {
        uint256 orderId = orderIdHash >> 160;
        orderStatus[orderIdHash].orderType = orderType;
        orderStatus[orderIdHash].orderId = orderId;
        orderStatus[orderIdHash].isValidated = isValidated;
        orderStatus[orderIdHash].isCanceled = isCanceled;
        orderStatus[orderIdHash].numerator = numerator;
        orderStatus[orderIdHash].denominator = denominator;

        emit OrderStatusChanged(
            orderStatus[orderIdHash].orderId,
            orderIdHash,
            orderStatus[orderIdHash]
        );
    }

    function _computeAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) private view returns (address) {
        return
            ERC6551Registry.account(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt
            );
    }

    function _validAccount(
        IMOPNERC6551Account account,
        Order memory order
    ) private view {
        (, address nftToken, uint256 tokenId) = account.token();
        // check nftToken
        require(nftToken == order.nftToken, "TOKEN_CONTRACT_MISMATCH");
        // check account address
        require(
            address(account) ==
                _computeAccount(
                    order.implementation,
                    block.chainid,
                    nftToken,
                    tokenId,
                    order.salt
                ),
            "ACCOUNT_ADDRESS_MISMATCH"
        );
        require(account.rentEndBlock() < block.number, "ACCOUNT_RENTED");
    }

    function withdrawFee(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        uint256 balance;
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }

        require(amount > 0 && balance >= amount, "INSUFFICIENT_BALANCE");

        if (token == address(0)) {
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "TRANSFER_FAILED");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }

        emit FeeWithdrawed(token, to, amount);
    }
}
