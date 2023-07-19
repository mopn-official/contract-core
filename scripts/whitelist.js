const { ethers } = require("hardhat");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");

const main = async () => {
  const whitelistjson = fs.readFileSync("./scripts/whitelist.json");
  console.log(JSON.parse(whitelistjson));
  const tree = StandardMerkleTree.of(JSON.parse(whitelistjson), ["address", "uint256"]);

  const proof = tree.getProof(2);

  console.log(tree.root);
  console.log(proof);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
