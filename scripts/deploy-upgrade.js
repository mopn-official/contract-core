const { ethers, upgrades } = require("hardhat");

async function main() {
  const BoxV2 = await ethers.getContractFactory("BoxV2");
  const box = await upgrades.upgradeBeacon("0xB201D538febaaef48499176f848b82153229Bd25", BoxV2);
  const upgraded = BoxV2.attach("0xBF3a672C9443CD7aDe4e79D0E385C3281911463F");
  console.log("Box upgraded to ", upgraded.address);
  const value = await upgraded.retrieve();
  console.log(value);
}

main();
