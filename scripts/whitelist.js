const { ethers } = require("hardhat");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");
const IPFS = require("ipfs-infura");

const main = async () => {
  const whitelistjson = fs.readFileSync("./scripts/whitelist.json");
  console.log(JSON.parse(whitelistjson));
  const tree = StandardMerkleTree.of(JSON.parse(whitelistjson), ["address"]);

  const proof = tree.getProof(0);

  const ipfs = new IPFS({
    host: "ipfs.infura.io",
    port: 5001,
    protocol: "https",
    projectId: process.env.INFURA_IPFS_PROJECTID,
    projectSecret: process.env.INFURA_IPFS_PROJECTSECRET,
  });

  const whitelistCID = await ipfs.addJSON(whitelistjson);
  console.log(whitelistCID);
  console.log(tree.root);
  console.log(proof);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
