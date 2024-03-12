const fs = require("fs");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

async function main() {
  const network = process.argv[2];

  console.log("gen " + network + " whitelist start");

  const collections = loadWhiteCollections(network);

  const namemap = {};
  const whitlist = [];
  const opentotalmopnpointmap = [0, 3000000, 10000000];
  let i = 0;
  for (const key in collections) {
    for (const collection of collections[key]) {
      whitlist.push([collection.collectionAddress, opentotalmopnpointmap[i]]);
      namemap[collection.collectionAddress] = collection.collectionName;
    }
    i++;
  }

  const merkleTree = StandardMerkleTree.of(whitlist, ["address", "uint256"]);

  console.log("Merkle Root:", merkleTree.root);

  const whitetree = [];
  for (const white of whitlist) {
    for (const [i, v] of merkleTree.entries()) {
      if (v[0] === white[0]) {
        const proof = merkleTree.getProof(i);
        whitetree.push({
          name: namemap[white[0]],
          collectionAddress: white[0],
          opentotalmopnpoint: white[1],
          merkleProof: proof,
        });
      }
    }
  }

  saveWhiteList(network, whitetree);
  saveWhiteListTree(network, merkleTree.dump());
  console.log("gen " + network + " whitelist finish");
}

function loadWhiteCollections(network) {
  const deployConf = JSON.parse(
    fs.readFileSync("./src/preprod/whitecollections/" + network + ".json")
  );

  if (!deployConf) {
    console.log("no white collections");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveWhiteList(network, whitelist) {
  fs.writeFile(
    "./src/preprod/whitelist/" + network + ".json",
    JSON.stringify(whitelist, null, 4),
    "utf8",
    function (err) {
      if (err) throw err;
    }
  );
}

function saveWhiteListTree(network, whitelist) {
  fs.writeFile(
    "./src/preprod/data/" + network + "_tree.json",
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
