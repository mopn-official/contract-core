const fs = require("fs");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

async function main() {
  console.log("gen goerli whitelist start");

  const mocknfts = loadMockNFTs();

  const mintablemocknfts = loadMintableMockNFTs();

  const whitlist = [];
  let i = 1;
  for (const key in mocknfts.collections) {
    let collection = {
      name: mocknfts.collections[key].name,
      collectionAddress: mocknfts.collections[key].collectionAddress,
      opentotalmopnpoint: 0,
    };
    if (i > 50) {
      collection.opentotalmopnpoint = 3000;
    } else if (i > 10) {
      collection.opentotalmopnpoint = 1000;
    }
    whitlist.push(collection);
    i++;
  }

  i = 1;
  for (const key in mintablemocknfts.collections) {
    let collection = {
      name: mintablemocknfts.collections[key].name,
      collectionAddress: mintablemocknfts.collections[key].collectionAddress,
      opentotalmopnpoint: 0,
    };
    whitlist.push(collection);
    i++;
  }

  const whitelistTree = [];
  for (const collection of whitlist) {
    whitelistTree.push([collection.collectionAddress, collection.opentotalmopnpoint]);
  }

  const merkleTree = StandardMerkleTree.of(whitelistTree, ["address", "uint256"]);

  console.log("Merkle Root:", merkleTree.root);

  for (const key in whitlist) {
    for (const [i, v] of merkleTree.entries()) {
      if (v[0] === whitlist[key].collectionAddress) {
        const proof = merkleTree.getProof(i);
        whitlist[key].merkleProof = proof;
      }
    }
  }

  saveWhiteList(whitlist);
  saveWhiteListTree(merkleTree.dump());
  console.log("gen goerli whitelist finish");
}

function loadMockNFTs() {
  const deployConf = JSON.parse(fs.readFileSync("./scripts/mocknfts/nfts.json"));

  if (!deployConf) {
    console.log("no mock nfts");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function loadMintableMockNFTs() {
  const deployConf = JSON.parse(fs.readFileSync("./scripts/mocknfts/mintablenfts.json"));

  if (!deployConf) {
    console.log("no mintable mock nfts");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveWhiteList(whitelist) {
  fs.writeFile(
    "./scripts/whitelist/goerli.json",
    JSON.stringify(whitelist, null, 4),
    "utf8",
    function (err) {
      if (err) throw err;
    }
  );
}

function saveWhiteListTree(whitelist) {
  fs.writeFile(
    "./scripts/whitelist/goerli_tree.json",
    JSON.stringify(whitelist, null, 4),
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
