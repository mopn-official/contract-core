const { expect } = require("chai");
const hre = require("hardhat");
const { createSignature } = require("../src/rental/signature");

describe("MOPNRental", function () {
  let accounts;
  let mopnRental;
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
    nft = await TESTNFT.deploy();
    await nft.waitForDeployment();
    console.log("nft", await nft.getAddress());
    await nft.safeMint(renter.address, 100);

    MOPNGovernance = await ethers.getContractFactory("MOPNGovernance");
    governance = await MOPNGovernance.deploy();
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
    mopnRental = await MOPNRental.deploy(
      await offerToken.getAddress(),
      await registry.getAddress()
    );
    await mopnRental.waitForDeployment();
    console.log("mopnRental", await mopnRental.getAddress());

    MOPNERC6551Account = await ethers.getContractFactory("MOPNERC6551Account");
    accountImplementation = await MOPNERC6551Account.deploy(
      governance.getAddress(),
      mopnRental.getAddress()
    );
    await accountImplementation.waitForDeployment();

    MOPNERC6551AccountProxy = await ethers.getContractFactory("MOPNERC6551AccountProxy");
    accountProxy = await MOPNERC6551AccountProxy.deploy(
      governance.getAddress(),
      mopnRental.getAddress()
    );
    await accountProxy.waitForDeployment();

    const governanceset6551tx = await governance.updateERC6551Contract(
      registry.getAddress(),
      accountProxy.getAddress(),
      accountProxy.getAddress()
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
      await accountImplementation.getAddress(),
      chainId,
      await nft.getAddress(),
      1,
      0
    );

    await registry.createAccount(
      await accountImplementation.getAddress(),
      chainId,
      await nft.getAddress(),
      2,
      0,
      accountImplementation.interface.encodeFunctionData("setOwnershipMode", [1])
    );

    accountAddress2 = await registry.account(
      await accountImplementation.getAddress(),
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
      implementation: await accountImplementation.getAddress(),
      account: await account.getAddress(),
      quantity: "1",
      price: "10000000000000000",
      minDuration: "100",
      maxDuration: "86400",
      expiry: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
      feeRate: "25",
      feeReceiver: await mopnRental.getAddress(),
      salt: "0",
    };

    offerOrder = {
      orderType: 1, // 1 for OFFER
      orderId: 2,
      owner: offerer.address,
      nftToken: await nft.getAddress(),
      implementation: await accountImplementation.getAddress(),
      account: await account2.getAddress(),
      quantity: 1,
      price: "10000000000000000",
      minDuration: "100",
      maxDuration: "86400",
      expiry: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
      feeRate: "25",
      feeReceiver: await mopnRental.getAddress(),
      salt: "0",
    };

    cancelOrder = {
      orderType: 0, // 0 for LIST
      orderId: 3,
      owner: renter.address,
      nftToken: await nft.getAddress(),
      implementation: await accountImplementation.getAddress(),
      account: await account.getAddress(),
      quantity: 1,
      price: "10000000000000000",
      minDuration: 0,
      maxDuration: 0,
      expiry: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
      feeRate: "25",
      feeReceiver: await mopnRental.getAddress(),
      salt: "0",
    };
  });

  it("Should rent from list", async function () {
    const signature = await createSignature(await mopnRental.getAddress(), listOrder, renter);
    const paymentAmount = hre.ethers.parseEther("1"); // 定义支付金额

    await expect(
      mopnRental.connect(offerer).rentFromList(listOrder, 100, signature, { value: paymentAmount })
    ).to.emit(mopnRental, "OrderPaid");

    const rentOwner = await account.renter();
    expect(rentOwner).to.equal(offerer.address);
  });

  it("Should accept offer", async function () {
    const signature = await createSignature(await mopnRental.getAddress(), offerOrder, offerer);

    await offerToken.mint(offerer.address, "1000000000000000000");

    await offerToken.connect(offerer).approve(await mopnRental.getAddress(), "1000000000000000000");
    await expect(
      mopnRental
        .connect(renter)
        .acceptOffer(
          offerOrder,
          100,
          [await account2.getAddress()],
          "1000000000000000000",
          signature
        )
    ).to.emit(mopnRental, "OrderPaid");

    const rentOwner = await account.renter();
    expect(rentOwner).to.equal(offerer.address);
  });

  it("Should cancel order", async function () {
    const signature = await createSignature(await mopnRental.getAddress(), cancelOrder, renter);

    await expect(mopnRental.connect(renter).cancelOrder(cancelOrder, signature)).to.emit(
      mopnRental,
      "OrderStatusChanged"
    );
  });

  it("Shouldn't cancel paid order", async function () {
    listOrder.minDuration = 0;
    listOrder.maxDuration = 0;
    const signature = await createSignature(await mopnRental.getAddress(), listOrder, renter);

    await expect(mopnRental.connect(renter).cancelOrder(listOrder, signature)).to.be.rejectedWith(
      "ORDER_EXECUTED"
    );
  });

  it("Shouldn't double pay", async function () {
    listOrder.minDuration = 100;
    listOrder.maxDuration = 86400;
    const signature = await createSignature(await mopnRental.getAddress(), listOrder, renter);
    const paymentAmount = hre.ethers.parseEther("1"); // 定义支付金额

    await expect(
      mopnRental.rentFromList(listOrder, 100, signature, {
        value: paymentAmount,
      })
    ).to.be.rejectedWith("ORDER_EXECUTED");
  });

  it("should withdraw", async function () {
    await expect(
      mopnRental.withdrawFee(
        "0x0000000000000000000000000000000000000000",
        accounts[0],
        ethers.parseEther("0.025")
      )
    ).to.emit(mopnRental, "FeeWithdrawed");
    await expect(
      mopnRental.withdrawFee(await offerToken.getAddress(), accounts[0], ethers.parseEther("0.025"))
    ).to.emit(mopnRental, "FeeWithdrawed");
  });
});
