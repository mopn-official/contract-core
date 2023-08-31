const fs = require("fs");

async function main() {
  const thegraphbase = "https://api.thegraph.com/subgraphs/name/cyanface/mopn-";

  const network = process.argv[2];
  const deployConf = loadConf(network);
  if (!deployConf) {
    console.log("no deploy config for network " + network);
    return;
  }

  let config = {
    thegraph: thegraphbase + network,
    network: network,
    contracts: {},
  };

  if (network == "sepolia") {
    config.thegraph = "https://api.studio.thegraph.com/proxy/46530/mopn-sepolia/v0.0.2/";
  }

  console.log("gen config start");
  for (let i = 0; i < deployConf.contracts.length; i++) {
    contractName = deployConf.contracts[i];
    if (contractName == "MOPNLandMirror") {
      contractName = "MOPNLand";
    }
    config.contracts[contractName] = "";
    if (deployConf[deployConf.contracts[i]].address) {
      config.contracts[contractName] = deployConf[deployConf.contracts[i]].address;
    }
  }

  saveConfig(config, network);
  console.log("gen config finish");
}

function loadConf(network) {
  const deployConf = JSON.parse(fs.readFileSync("./scripts/deployconf/" + network + ".json"));

  if (!deployConf) {
    console.log("no deploy config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function loadPeripheryConf(network) {
  const deployConf = JSON.parse(
    fs.readFileSync("../contract-periphery/scripts/deployconf/" + network + ".json")
  );

  if (!deployConf) {
    console.log("no deploy config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveConfig(config, network) {
  fs.writeFile(
    "./configs/" + network + ".json",
    JSON.stringify(config, null, 4),
    "utf8",
    function (err) {
      if (err) throw err;
    }
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
