const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();

  const deployConf = loadConf();

  let contractName, Contract, contract;

  console.log("deploy start");
  for (let i = 0; i < deployConf.contracts.length; i++) {
    contractName = deployConf.contracts[i];
    if (!deployConf[contractName].address) {
      console.log("deploy " + contractName);
      if (deployConf[contractName].libraries) {
        let libraries = {
          libraries: {},
        };
        for (let j = 0; j < deployConf[contractName].libraries.length; j++) {
          libraries.libraries[deployConf[contractName].libraries[j]] =
            deployConf[deployConf[contractName].libraries[j]].address;
        }
        Contract = await ethers.getContractFactory(contractName, libraries);
      } else {
        Contract = await ethers.getContractFactory(contractName);
      }

      if (deployConf[contractName].constructparams) {
        contract = await Contract.deploy(...deployConf[contractName].constructparams);
      } else {
        contract = await Contract.deploy();
      }

      console.log("https://mumbai.polygonscan.com/tx/" + contract.deployTransaction.hash);
      await contract.deployed();
      deployConf[contractName].address = contract.address;
      deployConf[contractName].verified = false;
      console.log(contractName, ":", contract.address, " deployed.");
      saveConf(deployConf);
    } else {
      contract = await ethers.getContractAt(contractName, deployConf[contractName].address);
      console.log(contractName, ":", contract.address, " exist. No need to deploy");
    }
  }
  console.log("deploy finish");

  console.log("transfer owner check start");
  for (let i = 0; i < deployConf.contracts.length; i++) {
    contractName = deployConf.contracts[i];
    if (deployConf[contractName].transOwnerTo) {
      const expectOwner = ethers.utils.isAddress(deployConf[contractName].transOwnerTo)
        ? deployConf[contractName].transOwnerTo
        : deployConf[deployConf[contractName].transOwnerTo].address;
      contract = await ethers.getContractAt(contractName, deployConf[contractName].address);
      const currentOwner = await contract.owner();
      if (expectOwner != currentOwner) {
        console.log(contractName, "'s expect owner mismatch, begin to transfer ownership");
        const transownertx = await contract.transferOwnership(expectOwner);
        await transownertx.wait();
        console.log("ownership transferred");
        saveConf(deployConf);
      } else {
        console.log(contractName, "'s owner matched.");
      }
    }
  }
  console.log("transfer owner check finish");

  console.log("cross Contract check start");
  for (let i = 0; i < deployConf.contracts.length; i++) {
    contractName = deployConf.contracts[i];
    if (deployConf[contractName].crossContractCheck) {
      for (let j = 0; j < deployConf[contractName].crossContractCheck.length; j++) {
        contract = await ethers.getContractAt(contractName, deployConf[contractName].address);
        let needupdate = false;
        let updateParams = [];
        for (let k = 0; k < deployConf[contractName].crossContractCheck[j].contracts.length; k++) {
          const expectAttr = ethers.utils.isAddress(
            deployConf[contractName].crossContractCheck[j].contracts[k]
          )
            ? deployConf[contractName].crossContractCheck[j].contracts[j]
            : deployConf[deployConf[contractName].crossContractCheck[j].contracts[k]].address;
          updateParams.push(expectAttr);

          const currentAttr = await eval(
            "contract." + deployConf[contractName].crossContractCheck[j].attributes[k] + "()"
          );

          if (expectAttr != currentAttr) {
            needupdate = true;
          }
        }
        if (needupdate) {
          console.log(
            contractName,
            "'s attr",
            j,
            " needs to update, begin to call ",
            deployConf[contractName].crossContractCheck[j].updateMethod
          );
          const updatetx = await eval(
            "contract." +
              deployConf[contractName].crossContractCheck[j].updateMethod +
              "(...updateParams)"
          );
          await updatetx.wait();
          console.log("update succeed");
          saveConf(deployConf);
        } else {
          console.log(contractName, "'s attr", j, " no needs to update");
        }
      }
    }
  }
  console.log("cross Contract check finish");

  console.log("begin verify contracts on " + hre.network.name + "scan");
  for (let i = 0; i < deployConf.contracts.length; i++) {
    contractName = deployConf.contracts[i];
    if (!deployConf[contractName].verified) {
      console.log("begin to verify ", contractName, " at ", deployConf[contractName].address);
      try {
        await hre.run("verify:verify", {
          address: deployConf[contractName].address,
          constructorArguments: deployConf[contractName].constructparams
            ? deployConf[contractName].constructparams
            : [],
        });
        deployConf[contractName].verified = true;
        saveConf(deployConf);
      } catch (e) {
        if (
          e.toString() == "Reason: Already Verified" ||
          e.toString() == "NomicLabsHardhatPluginError: Contract source code already verified"
        ) {
          deployConf[contractName].verified = true;
          saveConf(deployConf);
        } else {
          console.log("verify failed " + e.toString());
        }
      }
    } else {
      console.log(contractName, " already verified");
    }
  }
  console.log("all contracts verifed");
}

function loadConf() {
  const deployConf = JSON.parse(
    fs.readFileSync("./scripts/deployconf/" + hre.network.name + ".json")
  );

  if (!deployConf) {
    console.log("no deploy config");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveConf(deployConf) {
  fs.writeFile(
    "./scripts/deployconf/" + hre.network.name + ".json",
    JSON.stringify(deployConf),
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
