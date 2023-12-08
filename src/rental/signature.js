const hre = require("hardhat");

let chainId = hre.network.config.chainId;

async function createSignature(rentalAddress, order, signer) {
  // EIP-712 schema
  const domain = {
    name: "MOPNRental",
    version: "1",
    chainId: chainId, // Replace with your chainId
    verifyingContract: rentalAddress, // Replace with your contract's address
  };

  const types = {
    Order: [
      { name: "orderType", type: "uint8" },
      { name: "orderId", type: "uint256" },
      { name: "owner", type: "address" },
      { name: "nftToken", type: "address" },
      { name: "implementation", type: "address" },
      { name: "account", type: "address" },
      { name: "quantity", type: "uint256" },
      { name: "price", type: "uint256" },
      { name: "minDuration", type: "uint256" },
      { name: "maxDuration", type: "uint256" },
      { name: "expiry", type: "uint256" },
      { name: "feeRate", type: "uint256" },
      { name: "feeReceiver", type: "address" },
      { name: "salt", type: "uint256" },
    ],
  };

  const value = {
    orderType: order.orderType,
    orderId: order.orderId,
    owner: order.owner,
    nftToken: order.nftToken,
    implementation: order.implementation,
    account: order.account,
    quantity: order.quantity,
    price: order.price,
    minDuration: order.minDuration,
    maxDuration: order.maxDuration,
    expiry: order.expiry,
    feeRate: order.feeRate,
    feeReceiver: order.feeReceiver,
    salt: order.salt,
  };

  // Sign the data
  // console.log(owner.address, signer.address, value);
  const signature = await signer.signTypedData(domain, types, value);
  console.log("signature", signature);
  return signature;
}

module.exports = {
  createSignature,
};
