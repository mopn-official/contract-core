const fs = require("fs");
const axios = require("axios");

async function main() {
  const network = process.argv[2];
  let realnetwork = network;
  if (network == "goerli_dev") realnetwork = "goerli";

  const blockdata = await axios.get(
    "https://api.etherscan.io/api?module=proxy&action=eth_blockNumber"
  );
  if (typeof blockdata.data.status == undefined) {
    console.log("get blocknumber error");
    return;
  }
  const blocknumber = eval(blockdata.data.result).toString(10);
  console.log("blocknumber: " + blocknumber);

  const thegraphbase = "https://api.thegraph.com/subgraphs/name/cyanface/mopn-";

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

  const thegraphConf = loadTheGraphConf(network);
  for (const key in thegraphConf) {
    thegraphConf[key].address = config.contracts[key];
    thegraphConf[key].startBlock = parseInt(blocknumber);
  }

  saveTheGraphConfig(thegraphConf, network);
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

function loadTheGraphConf(network) {
  if (network == "goerli_dev") network = "goerli";
  const thegraphConf = JSON.parse(fs.readFileSync("../thegraph/networks.json"));

  if (!thegraphConf) {
    console.log("no thegraph config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  if (!thegraphConf[network]) {
    console.log("no thegraph config for network " + network);
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return thegraphConf[network];
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

function saveTheGraphConfig(config, network) {
  if (network == "goerli_dev") network = "goerli";
  const thegraphConf = JSON.parse(fs.readFileSync("../thegraph/networks.json"));

  if (!thegraphConf) {
    console.log("no thegraph config");
    console.error(error);
    process.exitCode = 1;
    return;
  }
  thegraphConf[network] = config;
  fs.writeFile(
    "../thegraph/networks.json",
    JSON.stringify(thegraphConf, null, 4),
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
