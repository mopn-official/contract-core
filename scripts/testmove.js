const { ethers } = require("hardhat");
const fs = require("fs");
const contract_config = JSON.parse(fs.readFileSync("./configs/goerli_dev.json"));
console.log(contract_config);

async function main() {
  const erc6551helper = await ethers.getContractAt(
    "MOPNERC6551AccountHelper",
    contract_config.contracts["MOPNERC6551AccountHelper"]
  );
  const mopn = await ethers.getContractAt("MOPN", contract_config.contracts["MOPN"]);

  const account = await erc6551helper.computeAccount(
    contract_config.contracts["MOPNERC6551AccountProxy"],
    5,
    "0x9bA6e2D3c9c1e7C1648C5cFC8c99c4b271eDaBc3",
    57,
    0
  );

  console.log(account);

  // const erc6551proxy = await ethers.getContractAt("MOPNERC6551AccountProxy", account);
  // const tx = await erc6551helper.multicall([
  //   erc6551helper.interface.encodeFunctionData("createAccount", [
  //     contract_config.contracts["MOPNERC6551AccountProxy"],
  //     5,
  //     "0x9bA6e2D3c9c1e7C1648C5cFC8c99c4b271eDaBc3",
  //     57,
  //     0,
  //     erc6551proxy.interface.encodeFunctionData("initialize"),
  //   ]),
  //   erc6551helper.interface.encodeFunctionData("proxyCall", [
  //     account,
  //     mopn.address,
  //     0,
  //     // 4 0
  //     mopn.interface.encodeFunctionData("moveTo", [10041000, 0]),
  //   ]),
  // ]);
  // await tx.wait();

  const erc6551account = await ethers.getContractAt("MOPNERC6551Account", account);
  // const tx = await erc6551account.executeCall(
  //   mopn.address,
  //   0,
  //   // 4 0
  //   mopn.interface.encodeFunctionData("moveTo", [10001000, 0])
  // );
  // await tx.wait();

  const tx = await erc6551account.rentExecute("0x23D2D1089890F34d723f35d4B36Af35B75EaBF0b", 300);
  await tx.wait();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
