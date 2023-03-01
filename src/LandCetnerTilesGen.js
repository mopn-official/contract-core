const hexGridsMath = require("./MOPNMath");
const fs = require("fs");

CenterTileArr = {};

for (let i = 1; i < 10982; i++) {
  CenterTileArr[hexGridsMath.LandCenterTile(i)] = i;
}

let json = JSON.stringify(CenterTileArr);
console.log(json);
fs.writeFile("LandCenterTiles.json", json, "utf8", function (err) {
  if (err) throw err;
  console.log("complete");
});
