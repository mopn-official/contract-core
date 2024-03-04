const { ethers } = require("hardhat");
const fs = require("fs");
const { time, mine } = require("@nomicfoundation/hardhat-network-helpers");
const { ZeroAddress } = require("ethers");

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
    const accounts = config.networks.hardhat.accounts;
    console.log(accounts);
    const hdNodeWallet = ethers.HDNodeWallet.fromPhrase(accounts.mnemonic);
    let wallet = hdNodeWallet.derivePath(accounts.path + "/0");
    console.log(wallet);
    wallet = hdNodeWallet.derivePath(accounts.path + "/1");
    console.log(wallet);
    const MOPNGovernance = await ethers.getContractFactory("MOPNGovernance");
    mopngovernance = await MOPNGovernance.deploy();
    await mopngovernance.waitForDeployment();
    console.log("MOPNGovernance", await mopngovernance.getAddress());
  });

  it("deply erc6551", async function () {
    const ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
    erc6551registry = await ERC6551Registry.deploy();
    await erc6551registry.waitForDeployment();
    console.log("ERC6551Registry", await erc6551registry.getAddress());

    const MOPNERC6551Account = await ethers.getContractFactory("MOPNERC6551Account");
    erc6551account = await MOPNERC6551Account.deploy(await mopngovernance.getAddress());
    await erc6551account.waitForDeployment();
    console.log("MOPNERC6551Account", await erc6551account.getAddress());

    const MOPNERC6551AccountProxy = await ethers.getContractFactory("MOPNERC6551AccountProxy");
    erc6551accountproxy = await MOPNERC6551AccountProxy.deploy(await erc6551account.getAddress());
    await erc6551accountproxy.waitForDeployment();
    console.log("MOPNERC6551AccountProxy", await erc6551accountproxy.getAddress());

    const MOPNERC6551AccountHelper = await ethers.getContractFactory("MOPNERC6551AccountHelper");
    erc6551accounthelper = await MOPNERC6551AccountHelper.deploy(await mopngovernance.getAddress());
    await erc6551accounthelper.waitForDeployment();
    console.log("MOPNERC6551AccountHelper", await erc6551accounthelper.getAddress());
  });

  it("deploy MOPN contracts", async function () {
    const MOPN = await ethers.getContractFactory("MOPN");
    mopn = await MOPN.deploy(
      mopngovernance.getAddress(),
      60000000,
      "0x7e53a927cd6ec3af3b9bb0b1aec96074c82344674a0d328ab20431416cccb45f"
    );
    await mopn.waitForDeployment();
    console.log("MOPN", await mopn.getAddress());
  });

  it("update contract attributes", async function () {
    const governanceset6551tx = await mopngovernance.updateERC6551Contract(
      await erc6551registry.getAddress(),
      await erc6551accountproxy.getAddress(),
      await erc6551accounthelper.getAddress()
    );
    await governanceset6551tx.wait();
  });

  it("test try cache", async function () {
    const tx = await erc6551registry.createAccount(
      await erc6551accountproxy.getAddress(),
      31337,
      "0x1fE6879DCDdfC5b1c1Fa19bf42FD3D85fFF282e4",
      3,
      0,
      "0x"
    );
    await tx.wait();

    const account = await erc6551registry.account(
      await erc6551accountproxy.getAddress(),
      31337,
      "0x1fE6879DCDdfC5b1c1Fa19bf42FD3D85fFF282e4",
      3,
      0
    );

    const accountContract = await ethers.getContractAt("MOPNERC6551Account", account);
    console.log(await accountContract.owner());
  });
});
