const { ethers } = require("hardhat");

async function main() {
  const erc6551proxy = await ethers.getContractAt(
    "MOPNERC6551AccountProxy",
    "0xE9B2c36476206e484F51aFAF32b9f0bf2E275B7d"
  );
  const mopn = await ethers.getContractAt("MOPN", "0xaE3D529e76CcD83dB2b791972aC0Eba2dD91Aebf");

  console.log(mopn.interface.encodeFunctionData("moveTo", [10041000, 0]));
  const tx = await erc6551proxy.multicall([
    erc6551proxy.interface.encodeFunctionData("createAccount", [
      "0x83510500dD42D1Ff5aA227ce42906504f910686b",
      5,
      "0x9bA6e2D3c9c1e7C1648C5cFC8c99c4b271eDaBc3",
      57,
      0,
      "0x",
    ]),
    erc6551proxy.interface.encodeFunctionData("proxyCall", [
      "0x41269CeD87AEF7c66aB02661A0dEcc833aD7be12",
      mopn.address,
      0,
      // 4 0
      mopn.interface.encodeFunctionData("moveTo", [10041000, 0]),
    ]),
  ]);
  await tx.wait();

  // const account = await ethers.getContractAt(
  //   "MOPNERC6551Account",
  //   "0x49a162365A7Af698907f5103BCbCC660709e9710"
  // );
  // const tx = await account.executeCall(
  //   mopn.address,
  //   0,
  //   mopn.interface.encodeFunctionData("moveTo", [10001000, 0])
  // );
  // await tx.wait();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
