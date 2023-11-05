const { expect } = require("chai");
const hre = require("hardhat");
const { createSignature } = require("../src/rental/signature");

describe("MOPNRental", function () {
  let accounts;
  let mopnRental;
  let mopnRentalProxy;
  let offerToken;
  let account;
  let account2;
  let nft;
  let accountImplementation;
  let TestERC6551Account;
  let renter;
  let offerer;
  let listOrder;
  let offerOrder;
  let cancelOrder;
  let chainId = hre.network.config.chainId;

  before(async function () {
    accounts = await hre.ethers.getSigners();
    renter = accounts[0];
    offerer = accounts[1];
    console.log("renter", renter.address);

    TESTNFT = await ethers.getContractFactory("TESTNFT");
    nft = await TESTNFT.deploy(renter.address);
    await nft.waitForDeployment();
    console.log("nft", await nft.getAddress());
    await nft.safeMint(renter.address, 100);

    MOPNGovernance = await ethers.getContractFactory("MOPNGovernance");
    governance = await MOPNGovernance.deploy(renter.address);
    await governance.waitForDeployment();
    console.log("governance", await governance.getAddress());

    MOCKWETH = await ethers.getContractFactory("MOCKWETH");
    offerToken = await MOCKWETH.deploy();
    await offerToken.waitForDeployment();
    console.log("offerToken", await offerToken.getAddress());

    // account2 = await TestERC6551Account.deploy(renter.address);

    ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
    registry = await ERC6551Registry.deploy();
    await registry.waitForDeployment();

    MOPNRental = await ethers.getContractFactory("MOPNRental");
    mopnRental = await MOPNRental.deploy();
    await mopnRental.waitForDeployment();
    console.log("mopnRental", await mopnRental.getAddress());
    console.log(await mopnRental.owner());

    MOPNRentalProxy = await ethers.getContractFactory("MOPNRentalProxy");
    mopnRentalProxy = await MOPNRentalProxy.deploy(
      await mopnRental.getAddress(),
      mopnRental.interface.encodeFunctionData("initialize", [
        await offerToken.getAddress(),
        await registry.getAddress(),
        renter.address,
      ]),
      renter.address
    );
    await mopnRentalProxy.waitForDeployment();
    console.log("mopnRentalProxy", await mopnRentalProxy.getAddress());

    mopnRentalProxy = await hre.ethers.getContractAt(
      "MOPNRental",
      await mopnRentalProxy.getAddress()
    );
    console.log("mopnRentalProxy", await mopnRentalProxy.getAddress());
    console.log(await mopnRentalProxy.owner());
    console.log(await mopnRentalProxy.eip712Domain());

    MOPNERC6551Account = await ethers.getContractFactory("MOPNERC6551Account");
    accountImplementation = await MOPNERC6551Account.deploy(
      await governance.getAddress(),
      await mopnRentalProxy.getAddress()
    );
    await accountImplementation.waitForDeployment();
    console.log("MOPNERC6551Account", await accountImplementation.getAddress());

    MOPNERC6551AccountProxy = await ethers.getContractFactory("MOPNERC6551AccountProxy");
    accountProxy = await MOPNERC6551AccountProxy.deploy(
      await governance.getAddress(),
      await accountImplementation.getAddress()
    );
    await accountProxy.waitForDeployment();
    console.log("MOPNERC6551AccountProxy", await accountProxy.getAddress());

    const governanceset6551tx = await governance.updateERC6551Contract(
      await registry.getAddress(),
      await accountProxy.getAddress(),
      await accountProxy.getAddress()
    );
    await governanceset6551tx.wait();

    const governancesetaccounttx = await governance.add6551AccountImplementation(
      accountImplementation.getAddress()
    );
    await governancesetaccounttx.wait();

    await registry.createAccount(
      await accountImplementation.getAddress(),
      chainId,
      await nft.getAddress(),
      1,
      0,
      accountImplementation.interface.encodeFunctionData("setOwnershipMode", [1])
    );

    accountAddress = await registry.account(
      await accountProxy.getAddress(),
      chainId,
      await nft.getAddress(),
      1,
      0
    );

    await registry.createAccount(
      await accountProxy.getAddress(),
      chainId,
      await nft.getAddress(),
      2,
      0,
      accountImplementation.interface.encodeFunctionData("setOwnershipMode", [1])
    );

    accountAddress2 = await registry.account(
      await accountProxy.getAddress(),
      chainId,
      await nft.getAddress(),
      2,
      0
    );

    console.log("accountAddress", accountAddress);
    console.log("account2Address", accountAddress2);

    account = await ethers.getContractAt("MOPNERC6551Account", accountAddress);
    account2 = await ethers.getContractAt("MOPNERC6551Account", accountAddress2);

    // await account.waitForDeployment();
    // await account2.waitForDeployment();
    console.log("account", await account.getAddress());
    console.log("account2", await account2.getAddress());

    // await account.rentPermit(await mopnRental.getAddress(), 60 * 60 * 24);
    // await account2.rentPermit(await mopnRental.getAddress(), 60 * 60 * 24);

    listOrder = {
      orderType: "0", // 0 for LIST
      orderId: "1",
      owner: renter.address,
      nftToken: await nft.getAddress(),
      implementation: await accountProxy.getAddress(),
      account: await account.getAddress(),
      quantity: "1",
      price: "10000000000000000",
      minDuration: "100",
      maxDuration: "86400",
      expiry: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
      feeRate: "25",
      feeReceiver: await mopnRentalProxy.getAddress(),
      salt: "0",
    };

    offerOrder = {
      orderType: 1, // 1 for OFFER
      orderId: 2,
      owner: offerer.address,
      nftToken: await nft.getAddress(),
      implementation: await accountProxy.getAddress(),
      account: await account2.getAddress(),
      quantity: 1,
      price: "10000000000000000",
      minDuration: "100",
      maxDuration: "86400",
      expiry: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
      feeRate: "25",
      feeReceiver: await mopnRentalProxy.getAddress(),
      salt: "0",
    };

    cancelOrder = {
      orderType: 0, // 0 for LIST
      orderId: 3,
      owner: renter.address,
      nftToken: await nft.getAddress(),
      implementation: await accountProxy.getAddress(),
      account: await account.getAddress(),
      quantity: 1,
      price: "10000000000000000",
      minDuration: 0,
      maxDuration: 0,
      expiry: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
      feeRate: "25",
      feeReceiver: await mopnRentalProxy.getAddress(),
      salt: "0",
    };
  });

  it("Should rent from list", async function () {
    const signature = await createSignature(await mopnRentalProxy.getAddress(), listOrder, renter);
    const paymentAmount = hre.ethers.parseEther("1"); // 定义支付金额

    await expect(
      mopnRentalProxy
        .connect(offerer)
        .rentFromList(listOrder, 100, signature, { value: paymentAmount })
    ).to.emit(mopnRentalProxy, "OrderPaid");

    const rentOwner = await account.renter();
    expect(rentOwner).to.equal(offerer.address);
  });

  it("Should accept offer", async function () {
    const signature = await createSignature(
      await mopnRentalProxy.getAddress(),
      offerOrder,
      offerer
    );

    await offerToken.mint(offerer.address, "1000000000000000000");

    await offerToken
      .connect(offerer)
      .approve(await mopnRentalProxy.getAddress(), "1000000000000000000");
    await expect(
      mopnRentalProxy
        .connect(renter)
        .acceptOffer(
          offerOrder,
          100,
          [await account2.getAddress()],
          "1000000000000000000",
          signature
        )
    ).to.emit(mopnRentalProxy, "OrderPaid");

    const rentOwner = await account.renter();
    expect(rentOwner).to.equal(offerer.address);
  });

  it("Should cancel order", async function () {
    const signature = await createSignature(
      await mopnRentalProxy.getAddress(),
      cancelOrder,
      renter
    );

    await expect(mopnRentalProxy.connect(renter).cancelOrder(cancelOrder, signature)).to.emit(
      mopnRentalProxy,
      "OrderStatusChanged"
    );
  });

  it("Shouldn't cancel paid order", async function () {
    listOrder.minDuration = 0;
    listOrder.maxDuration = 0;
    const signature = await createSignature(await mopnRentalProxy.getAddress(), listOrder, renter);

    await expect(
      mopnRentalProxy.connect(renter).cancelOrder(listOrder, signature)
    ).to.be.rejectedWith("ORDER_EXECUTED");
  });

  it("Shouldn't double pay", async function () {
    listOrder.minDuration = 100;
    listOrder.maxDuration = 86400;
    const signature = await createSignature(await mopnRentalProxy.getAddress(), listOrder, renter);
    const paymentAmount = hre.ethers.parseEther("1"); // 定义支付金额

    await expect(
      mopnRentalProxy.rentFromList(listOrder, 100, signature, {
        value: paymentAmount,
      })
    ).to.be.rejectedWith("ORDER_EXECUTED");
  });

  it("should withdraw", async function () {
    await expect(
      mopnRentalProxy.withdrawFee(
        "0x0000000000000000000000000000000000000000",
        accounts[0],
        ethers.parseEther("0.025")
      )
    ).to.emit(mopnRentalProxy, "FeeWithdrawed");
    await expect(
      mopnRentalProxy.withdrawFee(
        await offerToken.getAddress(),
        accounts[0],
        ethers.parseEther("0.025")
      )
    ).to.emit(mopnRentalProxy, "FeeWithdrawed");
  });
});
