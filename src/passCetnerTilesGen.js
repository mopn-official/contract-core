const hexGridsMath = require("./MOPNMath");
const fs = require("fs");

CenterTileArr = {};

for (let i = 1; i < 10982; i++) {
  CenterTileArr[hexGridsMath.PassCenterTile(i)] = i;
}

let json = JSON.stringify(CenterTileArr);
console.log(json);
fs.writeFile("passCenterTiles.json", json, "utf8", function (err) {
  if (err) throw err;
  console.log("complete");
});
