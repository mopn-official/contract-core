const { ethers, config } = require("hardhat");
const fs = require("fs");
const axios = require("axios");
const path = require("path");

async function main() {
  const mainnetnfts = loadMainnetWhiteCollections();
  let collectionsmetadata = loadCollectionsMetadata();

  const provider = new ethers.JsonRpcProvider(config.networks["mainnet"].url);
  const wallet = new ethers.Wallet(config.networks["mainnet"].accounts[0], provider);

  const blocknumber = await provider.getBlockNumber();

  /// IERC721 0x80ac58cd
  /// IERC721Metadata 0x5b5e139f

  for (const mainnetnft of mainnetnfts) {
    for (const mainnetAddress of mainnetnft) {
      if (!collectionsmetadata[mainnetAddress]) {
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

              console.log(mainnetAddress, name, symbol, baseURI, extURI);

              collectionsmetadata[mainnetAddress] = {
                mainnetAddress: mainnetAddress,
                name: name,
                symbol: symbol,
                baseURI: baseURI,
                extURI: extURI,
                tokenURIexample: tokenURI,
              };
              saveCollectionsmetadata(collectionsmetadata);
            }
          } else {
            console.log(mainnetAddress, "not 721");
          }
        } catch (e) {
          console.log(e);
          console.log(mainnetAddress, "jumped");
        }
      }
    }
  }
}

function loadMainnetWhiteCollections() {
  const deployConf = JSON.parse(fs.readFileSync("./src/preprod/whitecollections/mainnet.json"));

  if (!deployConf) {
    console.log("no mainnet nfts");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function loadCollectionsMetadata() {
  const deployConf = JSON.parse(
    fs.readFileSync("./src/preprod/testnetmirror/collectionsmetadata.json")
  );

  if (!deployConf) {
    console.log("no collectionsmetadata");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveCollectionsmetadata(deployConf) {
  fs.writeFile(
    "./src/preprod/testnetmirror/collectionsmetadata.json",
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
