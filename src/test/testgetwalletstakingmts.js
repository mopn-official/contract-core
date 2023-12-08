const { config } = require("hardhat");
const ethers = require("ethers");

async function main() {
  const provider = new ethers.JsonRpcProvider(config.networks["goerli_dev"].url);

  const MOPNDataabi = [
    "function getWalletStakingMTs(address[] memory collections) public view returns (uint256 amount)",
  ];
  const mopndata = new ethers.Contract(
    "0x1716417A14CC225Ab0A5Dab6A432B4d319D1c723",
    MOPNDataabi,
    provider
  );
  const amount = await mopndata.getWalletStakingMTs(
    ["0x82c46c4ea58b7d6d87704ecd459ee9efbf458b26"],
    { from: "0xcEf831B24dD65eb8eaeA890D48115eD374bbdcc0" }
  );
  console.log(amount);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
