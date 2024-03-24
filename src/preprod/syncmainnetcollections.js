const fs = require("fs");
const fetch = require('node-fetch');

async function main() {

  console.log("gen mainnet whitecollections start");

  const elementbest = loadElementBest();

  const whitecollections = [[]];

  for(const collection of elementbest) {
    if(collection.node.collection.contracts[0].tokenType != "ERC721") {
      continue;
    }
    const elementCollection = await getElementCollectionAddress(collection.node.collection.slug);
    const collectionAddress = elementCollection.data.contracts[0]['address'];
    whitecollections[0].push({
      "collectionAddress": collectionAddress,
      "collectionName": collection.node.collection.name,
    });
    console.log({
      "collectionAddress": collectionAddress,
      "collectionName": collection.node.collection.name,
    });
  }
  
  saveWhiteCollections(whitecollections);
  console.log("gen mainnet whiltecollections finish");
}

async function getElementCollectionAddress(slug) {
  const url = 'https://api.element.market/openapi/v1/collection?collection_slug=' + slug;
  const options = {
    method: 'GET',
    headers: {accept: 'application/json', 'X-Api-Key': 'f008268b9233ce8dd5eae85d61274773'}
  };
  
  const res = await fetch(url, options)
  return res.json();
} 


function loadElementBest() {
  const deployConf = JSON.parse(
    fs.readFileSync("./src/preprod/whitecollections/elementbest.json")
  );

  if (!deployConf) {
    console.log("no element best collections");
    console.error(error);
    process.exitCode = 1;
    return;
  }

  return deployConf;
}

function saveWhiteCollections(whitecollections) {
  fs.writeFile(
    "./src/preprod/whitecollections/blast_mainnet.json",
    JSON.stringify(whitecollections, null, 4),
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
