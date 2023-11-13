const MOPNContract = require("./MOPNContract");
const MOPNMath = require("../simulator/MOPNMath");
const TheGraph = require("../mopnhelper/TheGraph");

async function main() {
  // MOPNContract.setCurrentAccount(1);
  // console.log(await MOPNContract.moveTo("0x34a08ac41031d82c8f47c83705913bccca18465b", 1, 10300980));
  // console.log(await MOPNContract.buybomb(1));
  // console.log(await MOPNContract.stackMT('0x34a08ac41031d82c8f47c83705913bccca18465b', 1000000000));
  // console.log(await MOPNContract.removeStakingMT('0x34a08ac41031d82c8f47c83705913bccca18465b', "1000000000000000000000"));
  // const accounts = [
  //   "0xc6a3d78d7f2ddcb807dcb0c76a1b2145fa88c956",
  //   "0x315d5d65b95150efb88687055cdcd4dc310d13be",
  //   "0x3e2299d35e1caaf6aed27c7853ec6df80d022bad",
  // ];
  // for (const account of accounts) {
  //   console.log(await MOPNContract.getAccountNFTInfo(account));
  // }

  // console.log(MOPNMath.LandRingNum(7));

  // await MOPNContract.mintMockNFTs("0x1fE6879DCDdfC5b1c1Fa19bf42FD3D85fFF282e4", 5);

  // console.log(
  //   await MOPNContract.getMockNFTTokenUri("0x25B63766fAeF35Ef72ec4ACFc776c80001A4eeb4", 1)
  // );

  MOPNContract.setCurrentAccount(1);
  await MOPNContract.mintMockNFTs("0x46047f9D95EEb28aAbB6017E1D6EB3aBC8fDB611", 100);
  await MOPNContract.mintMockNFTs("0xaF5728834640C90aCCb2e082372EE40366559694", 100);
  await MOPNContract.mintMockNFTs("0x82C46C4EA58B7D6D87704ecD459ee9EfBf458B26", 100);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
