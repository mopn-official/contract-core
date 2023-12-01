const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const deployConf = loadConf();
  const mainnetnfts = loadMainnetNFTs();

  const provider = new ethers.JsonRpcProvider(config.networks["mainnet"].url);
  const wallet = new ethers.Wallet(config.networks["mainnet"].accounts[0], provider);

  const blocknumber = await provider.getBlockNumber();

  /// IERC721 0x80ac58cd
  /// IERC721Metadata 0x5b5e139f
  let i = 0;
  for (const mainnetnft of mainnetnfts) {
    for (const mainnetAddress of mainnetnft) {
      let opentotalmopnpoint = 0;
      if (i == 1) {
        opentotalmopnpoint = 500000;
      } else if (i == 2) {
        opentotalmopnpoint = 2000000;
      }
      if (!deployConf.collections[mainnetAddress]) {
        const contract = await ethers.getContractAt("IERC721Metadata", mainnetAddress, wallet);
        try {
          const is721 = await contract.supportsInterface("0x80ac58cd");
          if (is721) {
            const transfers = await contract.queryFilter(
              "Transfer",
              blocknumber - 3600,
              blocknumber
            );
            if (transfers.length > 0) {
              const transfer = transfers.pop();
              const tokenURI = await contract.tokenURI(transfer.args.tokenId);
              if (!tokenURI.length || tokenURI.length > 255) {
                console.log(mainnetAddress, "tokenURI error1");
                continue;
              }
              const pathinfo = path.parse(tokenURI);
              const baseURI = pathinfo.dir + "/";
              const extURI = pathinfo.ext;
              const name = await contract.name();
              const symbol = await contract.symbol();

              console.log(
                deployConf.collectionnumber,
                mainnetAddress,
                name,
                symbol,
                baseURI,
                extURI,
                opentotalmopnpoint
              );

              deployConf.collectionnumber++;
              deployConf.collections[mainnetAddress] = {
                mainnetAddress: mainnetAddress,
                collectionAddress: "",
                name: name,
                symbol: symbol,
                baseURI: baseURI,
                extURI: extURI,
                tokenURIexample: tokenURI,
                opentotalmopnpoint: opentotalmopnpoint,
              };
              saveConf(deployConf);
            }
          } else {
            console.log(mainnetAddress, "not 721");
          }
        } catch (e) {
          console.log(e);
          console.log(mainnetAddress, "jumped");
        }
      } else {
        deployConf.collections[mainnetAddress].opentotalmopnpoint = opentotalmopnpoint;
        saveConf(deployConf);
      }
    }
    i++;
  }
}

function loadConf() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/mocknfts/goerlimirrornfts.json"));

  if (!deployConf) {
    console.log("no goerli mirror nfts");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function loadMainnetNFTs() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/mocknfts/mainnetnfts.json"));

  if (!deployConf) {
    console.log("no mainnet nfts");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveConf(deployConf) {
  fs.writeFile(
    "./src/preprod/mocknfts/goerlimirrornfts.json",
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
