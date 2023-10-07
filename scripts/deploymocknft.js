const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require('axios');
const path = require('path');


async function main() {

  const deployConf = loadConf();

  let contractName, Contract, contract, mocknftfactroy, mocknftimplementation;

  console.log("deploy start");
  if (deployConf.factory.address != "") {
    mocknftfactroy = await ethers.getContractAt("MOCKNFTFactory", deployConf.factory.address);
    console.log("MOCKNFTFactory:", mocknftfactroy.address, " deployed.");
  } else {
    const MOCKNFTFactory = await ethers.getContractFactory("MOCKNFTFactory");
    mocknftfactroy = await MOCKNFTFactory.deploy();
    console.log("https://goerli.etherscan.io/tx/" + mocknftfactroy.deployTransaction.hash);
    await mocknftfactroy.deployed();
    console.log("MOCKNFTFactory:", mocknftfactroy.address, " deployed.");
    deployConf.factory.address = mocknftfactroy.address;
    saveConf(deployConf);
  }

  if (deployConf.implementation.address != "") {
    mocknftimplementation = await ethers.getContractAt("MOCKNFT", deployConf.implementation.address);
    console.log("MOCKNFT:", mocknftimplementation.address, " deployed.");
  } else {
    const MOCKNFT = await ethers.getContractFactory("MOCKNFT");
    mocknftimplementation = await MOCKNFT.deploy();
    console.log("https://goerli.etherscan.io/tx/" + mocknftimplementation.deployTransaction.hash);
    await mocknftimplementation.deployed();
    console.log("MOCKNFT:", mocknftimplementation.address, " deployed.");
    deployConf.implementation.address = mocknftimplementation.address;
    saveConf(deployConf);
  }

  const options = {
    method: 'GET',
    url: 'https://api.simplehash.com/api/v0/nfts/collections/top_v2?chains=ethereum&time_period=30d&limit=100',
    headers: { accept: 'application/json', 'X-API-KEY': 'cyanface_sk_f89ad03f-b89e-4a04-844b-ed8a5ee227c7_5uv3aqj1zrnjzpcu' }
  };

  const provider = new ethers.providers.JsonRpcProvider(config.networks['mainnet'].url);
  const wallet = new ethers.Wallet(config.networks['mainnet'].accounts[0], provider);

  const blocknumber = await provider.getBlockNumber();

  /// IERC721 0x80ac58cd
  /// IERC721Metadata 0x5b5e139f
  axios
    .request(options)
    .then(async function (response) {
      for (collection of response.data.collections) {
        if (collection.collection_details.top_contracts.length == 1) {
          const mainnetAddress = collection.collection_details.top_contracts[0].replace("ethereum.", "");
          if (deployConf.collections[mainnetAddress]) {
            console.log(mainnetAddress, "deployed collectionAddress is", deployConf.collections[mainnetAddress].collectionAddress);
            const contract = await ethers.getContractAt("MOCKNFT", deployConf.collections[mainnetAddress].collectionAddress);
            const baseURI = await contract.baseURI();
            const extURI = await contract.extURI();
            if (baseURI != deployConf.collections[mainnetAddress].baseURI) {
              console.log("update", mainnetAddress, deployConf.collections[mainnetAddress].collectionAddress, "baseURI from", baseURI, "to", deployConf.collections[mainnetAddress].baseURI);
              const tx = await contract.setBaseURI(deployConf.collections[mainnetAddress].baseURI);
              await tx.wait();
              console.log("done");
            }
            if (extURI != deployConf.collections[mainnetAddress].extURI) {
              console.log("update", mainnetAddress, deployConf.collections[mainnetAddress].collectionAddress, "extURI from", extURI, "to", deployConf.collections[mainnetAddress].extURI);
              const tx = await contract.setExtURI(deployConf.collections[collectionAddress].extURI);
              await tx.wait();
              console.log("done");
            }
            // const totalsupply = await contract.totalSupply();
            // console.log("total supply", totalsupply);
            // if (totalsupply < 5000) {
            //   console.log("mint another 1000");
            //   const tx = await contract.mint(1000);
            //   console.log("https://goerli.etherscan.io/tx/" + tx.hash);
            //   await tx.wait();
            //   console.log("done");
            // }
            if (!deployConf.collections[mainnetAddress].image_url && collection.collection_details.image_url) {
              deployConf.collections[mainnetAddress].image_url = collection.collection_details.image_url;
              saveConf(deployConf);
              console.log("save image url", collection.collection_details.image_url);
            }

          } else {
            const contract = await ethers.getContractAt("IERC721Metadata", mainnetAddress, wallet);
            try {
              const is721 = await contract.supportsInterface('0x80ac58cd');
              if (is721) {
                const transfers = await contract.queryFilter('Transfer', blocknumber - 3600, blocknumber);
                if (transfers.length > 0) {
                  const transfer = transfers.pop();
                  const tokenURI = await contract.tokenURI(transfer.args.tokenId);
                  if (tokenURI.length > 255) continue;
                  const pathinfo = path.parse(tokenURI);
                  const baseURI = pathinfo.dir + '/';
                  const extURI = pathinfo.ext;
                  const name = await contract.name();
                  const symbol = await contract.symbol();
                  console.log(deployConf.collectionnumber, mainnetAddress, name, symbol, baseURI, extURI);

                  const tx = await mocknftfactroy.createNewMockCollection(
                    mocknftimplementation.address,
                    deployConf.collectionnumber,
                    mocknftimplementation.interface.encodeFunctionData('initialize', [
                      name, symbol, baseURI, extURI
                    ])
                  );
                  console.log("https://goerli.etherscan.io/tx/" + tx.hash);
                  const receipt = await tx.wait();

                  let deployedAddress;
                  for (log of receipt.logs) {
                    if (log.address == mocknftfactroy.address) {
                      const event = mocknftfactroy.interface.parseLog(log);
                      deployedAddress = event.args.collectionAddress;
                      console.log(name, "deployed to", deployedAddress);
                    }
                  }
                  deployConf.collectionnumber++;
                  deployConf.collections[mainnetAddress] = {
                    "mainnetAddress": mainnetAddress,
                    'collectionAddress': deployedAddress,
                    'name': name,
                    'symbol': symbol,
                    'baseURI': baseURI,
                    'extURI': extURI,
                    "tokenURIexample": tokenURI
                  };
                  saveConf(deployConf);
                }
              }
            } catch (e) {
              console.log(e);
            }
          }
        }
      }
    })
    .catch(function (error) {
      console.error(error);
    });

  // for (let i = 0; i < deployConf.nfts.length; i++) {
  //   if (deployConf.nfts[i].address != "") {
  //     console.log(deployConf.nfts[i].name, ":", deployConf.nfts[i].address, " deployed.");
  //   } else {
  //     contractName = deployConf.nfts[i].name;
  //     console.log("deploy " + contractName);
  //     Contract = await ethers.getContractFactory("MOCKNFT");
  //     contract = await Contract.deploy(mocknftminer.address, deployConf.nfts[i].name, deployConf.nfts[i].symbol, deployConf.nfts[i].baseuri, deployConf.nfts[i].uriext);
  //     console.log("https://goerli.etherscan.io/tx/" + contract.deployTransaction.hash);
  //     await contract.deployed();
  //     console.log(contractName, ":", contract.address, " deployed.");
  //     deployConf.nfts[i].address = contract.address;
  //     saveConf(deployConf);
  //   }
  // }
  console.log("deploy finish");


  console.log("begin verify contracts on goerliscan");
  try {
    let verifyData = {
      address: mocknftfactroy.address
    };
    await hre.run("verify:verify", verifyData);
    verifyData = {
      address: mocknftimplementation.address
    };
    await hre.run("verify:verify", verifyData);
  } catch (e) {
    if (
      e.toString() == "Reason: Already Verified" ||
      e.toString() == "NomicLabsHardhatPluginError: Contract source code already verified"
    ) {
      console.log(deployConf.nfts[i].name + " already verified");
    } else {
      console.log("verify failed " + e.toString());
    }
  }

  console.log("all contracts verifed");
}

function loadConf() {
  const deployConf = JSON.parse(
    fs.readFileSync("./scripts/mocknfts/nfts.json")
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
    "./scripts/mocknfts/nfts.json",
    JSON.stringify(deployConf, null, 4),
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
