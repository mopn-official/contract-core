const { ethers } = require("hardhat");
const { getParsedEthersError } = require("@enzoferey/ethers-error-parser");

async function main() {
  const avatar = await ethers.getContractAt("Avatar", "0x53c9633bac2c2f54bde13e975b3a0302700a4e08");

  try {
    await avatar.moveTo(
      [
        "0xf005dd97d4e96b65effad658f2a40d2e5f425d43",
        4,
        [],
        0,
        "0x0000000000000000000000000000000000000000",
      ],
      10130987,
      83,
      12
    );
  } catch (error) {
    const parsederror = getParsedEthersError(error);
    console.log(parsederror);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
