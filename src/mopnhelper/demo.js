const MOPNContract = require("./MOPNContract");

async function main() {
  // MOPNContract.setCurrentAccount(1);

  // console.log(await MOPNContract.bidNFT("0x34a08ac41031d82c8f47c83705913bccca18465b", 1));
  // console.log(await MOPNContract.moveTo("0x34a08ac41031d82c8f47c83705913bccca18465b", 1, 10300980));

  console.log(await MOPNContract.buybomb(1));
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
