const { ethers } = require("hardhat");

describe("MOPN", function () {
  let testnft,
    testnft1,
    owner,
    erc6551registry,
    erc6551account,
    erc6551account1,
    erc6551accountproxy,
    erc6551accounthelper,
    tileMath,
    mopngovernance,
    accounts = [];

  it("deply Governance", async function () {
    [owner] = await ethers.getSigners();

    const MOPNGovernance = await ethers.getContractFactory("MOPNGovernance");
    mopngovernance = await MOPNGovernance.deploy(31337);
    await mopngovernance.deployed();
    console.log("MOPNGovernance", mopngovernance.address);
  });

  it("deply erc6551", async function () {
    const ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
    erc6551registry = await ERC6551Registry.deploy();
    await erc6551registry.deployed();
    console.log("ERC6551Registry", erc6551registry.address);

    const MOPNERC6551AccountProxy = await ethers.getContractFactory("MOPNERC6551AccountProxy");
    erc6551accountproxy = await MOPNERC6551AccountProxy.deploy(mopngovernance.address);
    await erc6551accountproxy.deployed();
    console.log("MOPNERC6551AccountProxy", erc6551accountproxy.address);

    const MOPNERC6551AccountHelper = await ethers.getContractFactory("MOPNERC6551AccountHelper");
    erc6551accounthelper = await MOPNERC6551AccountHelper.deploy(mopngovernance.address);
    await erc6551accounthelper.deployed();
    console.log("MOPNERC6551AccountHelper", erc6551accounthelper.address);

    const MOPNERC6551Account = await ethers.getContractFactory("MOPNERC6551Account");
    erc6551account = await MOPNERC6551Account.deploy(mopngovernance.address);
    await erc6551account.deployed();
    console.log("MOPNERC6551Account", erc6551account.address);

    const MOPNERC6551Account1 = await ethers.getContractFactory("MOPNERC6551Account1");
    erc6551account1 = await MOPNERC6551Account1.deploy(mopngovernance.address);
    await erc6551account1.deployed();
    console.log("MOPNERC6551Account1", erc6551account1.address);
  });

  it("deploy TESTNFT", async function () {
    const TESTNFT = await ethers.getContractFactory("TESTNFT");
    testnft = await TESTNFT.deploy();
    await testnft.deployed();
    console.log("TESTNFT ", testnft.address);

    const TESTNFT1 = await ethers.getContractFactory("TESTNFT");
    testnft1 = await TESTNFT1.deploy();
    await testnft1.deployed();
    console.log("TESTNFT1 ", testnft1.address);
  });

  it("update contract attributes", async function () {
    const governanceset6551tx = await mopngovernance.updateERC6551Contract(
      erc6551registry.address,
      erc6551accountproxy.address,
      erc6551accounthelper.address,
      [erc6551account.address, erc6551account1.address]
    );
    await governanceset6551tx.wait();
  });

  it("mint test nfts", async function () {
    let mintnfttx = await testnft.safeMint(owner.address, 8);
    await mintnfttx.wait();
    mintnfttx = await testnft1.safeMint(owner.address, 2);
    await mintnfttx.wait();
  });

  it("test create account", async function () {
    const tx = await erc6551registry.createAccount(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      0,
      0,
      erc6551accountproxy.interface.encodeFunctionData("initialize")
    );
    await tx.wait();

    const account = await erc6551registry.account(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      0,
      0
    );
    console.log("account", account);

    const accountProxyContract = await ethers.getContractAt("MOPNERC6551AccountProxy", account);
    console.log("account implementation", await accountProxyContract.implementation());
  });

  it("test upgrade implementation", async function () {
    const account = await erc6551registry.account(
      erc6551accountproxy.address,
      31337,
      testnft.address,
      0,
      0
    );
    console.log("account", account);

    const accountProxyContract = await ethers.getContractAt("MOPNERC6551AccountProxy", account);
    const uptx = await accountProxyContract.upgradeTo(erc6551account1.address);
    await uptx.wait();
    console.log("upgraded account implementation", await accountProxyContract.implementation());

    const accountContract = await ethers.getContractAt("MOPNERC6551Account1", account);
    console.log(await accountContract.testNewVersion());
  });
});
