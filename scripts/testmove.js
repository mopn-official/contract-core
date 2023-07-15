const { ethers } = require("hardhat");

async function main() {
  const erc6551proxy = await ethers.getContractAt(
    "MOPNERC6551AccountProxy",
    "0x9E0ae020B697FF1d42a825d91C3A74D6b38853C8"
  );
  const mopn = await ethers.getContractAt("MOPN", "0x53504135045cc0ec192ADce6BD435aAf66562BCB");

  console.log(mopn.interface.encodeFunctionData("moveTo", [10041000, 0]));
  // const tx = await erc6551proxy.multicall([
  //   erc6551proxy.interface.encodeFunctionData("createAccount", [
  //     "0xd966dfAa7c1068D2A83eC958e66693cE6136557F",
  //     5,
  //     "0x9bA6e2D3c9c1e7C1648C5cFC8c99c4b271eDaBc3",
  //     57,
  //     0,
  //     "0x",
  //   ]),
  //   // erc6551proxy.interface.encodeFunctionData("proxyCall", [
  //   //   "0x49a162365A7Af698907f5103BCbCC660709e9710",
  //   //   mopn.address,
  //   //   0,
  //   //   // 4 0
  //   //   mopn.interface.encodeFunctionData("moveTo", [10041000, 0]),
  //   // ]),
  // ]);
  // await tx.wait();

  const account = await ethers.getContractAt(
    "MOPNERC6551Account",
    "0x49a162365A7Af698907f5103BCbCC660709e9710"
  );
  const tx = await account.executeCall(
    mopn.address,
    0,
    mopn.interface.encodeFunctionData("moveTo", [10001000, 0])
  );
  await tx.wait();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
