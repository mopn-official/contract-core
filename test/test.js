const { ethers } = require("hardhat");
const fs = require("fs");
const { time, mine } = require("@nomicfoundation/hardhat-network-helpers");

describe("MOPN", function () {
  let owner,
    owner1,
    erc6551registry,
    erc6551account,
    erc6551accountproxy,
    erc6551accounthelper,
    mopngovernance,
    mopn;

  it("deply Governance", async function () {
    const MOPNGovernance = await ethers.getContractFactory("MOPNGovernance");
    mopngovernance = await MOPNGovernance.deploy();
    await mopngovernance.deployed();
    console.log("MOPNGovernance", mopngovernance.address);
  });

  it("deply erc6551", async function () {
    const ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
    erc6551registry = await ERC6551Registry.deploy();
    await erc6551registry.deployed();
    console.log("ERC6551Registry", erc6551registry.address);

    const MOPNERC6551Account = await ethers.getContractFactory("MOPNERC6551Account");
    erc6551account = await MOPNERC6551Account.deploy(
      mopngovernance.address,
      ethers.constants.AddressZero
    );
    await erc6551account.deployed();
    console.log("MOPNERC6551Account", erc6551account.address);

    const MOPNERC6551AccountProxy = await ethers.getContractFactory("MOPNERC6551AccountProxy");
    erc6551accountproxy = await MOPNERC6551AccountProxy.deploy(
      mopngovernance.address,
      erc6551account.address
    );
    await erc6551accountproxy.deployed();
    console.log("MOPNERC6551AccountProxy", erc6551accountproxy.address);

    const MOPNERC6551AccountHelper = await ethers.getContractFactory("MOPNERC6551AccountHelper");
    erc6551accounthelper = await MOPNERC6551AccountHelper.deploy(mopngovernance.address);
    await erc6551accounthelper.deployed();
    console.log("MOPNERC6551AccountHelper", erc6551accounthelper.address);
  });

  it("deploy MOPN contracts", async function () {
    const MOPN = await ethers.getContractFactory("MOPN");
    mopn = await MOPN.deploy(mopngovernance.address, 60000000, 0, 50400, 10000, 99999, false);
    await mopn.deployed();
    console.log("MOPN", mopn.address);
  });

  it("update contract attributes", async function () {
    const governanceset6551tx = await mopngovernance.updateERC6551Contract(
      erc6551registry.address,
      erc6551accountproxy.address,
      erc6551accounthelper.address
    );
    await governanceset6551tx.wait();

    const governancesetaccounttx = await mopngovernance.add6551AccountImplementation(
      erc6551account.address
    );
    await governancesetaccounttx.wait();
  });

  it("test try cache", async function () {
    const tx = await erc6551registry.createAccount(
      erc6551accountproxy.address,
      31337,
      "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB",
      3,
      0,
      "0x"
    );
    await tx.wait();

    const account = await erc6551registry.account(
      erc6551accountproxy.address,
      31337,
      "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB",
      3,
      0
    );

    const accountContract = await ethers.getContractAt("MOPNERC6551Account", account);
    console.log(await accountContract.owner());
  });
});
