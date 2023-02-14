const hexGridsMath = require("./HexGridsMath");

TEAWArr = {
  1: 0,
  5: 0,
  15: 0,
};
for (let i = 1; i < 10982; i++) {
  const TilesEAW = hexGridsMath.getPassTilesEAW(i);
  for (let k = 0; k < TilesEAW.length; k++) {
    TEAWArr[TilesEAW[k]]++;
    console.log(TEAWArr);
  }
}
