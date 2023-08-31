const fs = require("fs");

try {
  // read contents of the file
  const data = fs.readFileSync("./src/openseapro.data", "UTF-8");

  // split the contents by new line
  const lines = data.split(/\r?\n/);

  const collections = [];

  const multiAddressCollection = [];

  // print all lines
  lines.forEach((line) => {
    const data = JSON.parse(line);
    for (let i = 0; i < data.data.length; i++) {
      const item = data.data[i];
      if (item.stats.seven_day_volume < 1) continue;
      if (item.stats.top_offer_price < 0.01) continue;
      for (let k = 0; k < item.addresses.length; k++) {
        if (item.addresses[k].standard != "ERC721") continue;
        collections.push({
          name: item.name,
          address: item.addresses[k].address,
          seven_day_volume: item.stats.seven_day_volume,
          top_offer_price: item.stats.top_offer_price,
        });
      }
    }
  });

  console.log(collections.length);

  fs.writeFile(
    "./src/additionalMOPNPoint.json",
    JSON.stringify(collections, null, 4),
    "utf8",
    function (err) {
      if (err) throw err;
    }
  );
} catch (err) {
  console.error(err);
}
