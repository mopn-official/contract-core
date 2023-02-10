const hexGridsMath = require("./HexGridsMath");

BEPSArr = {
  1: 0,
  5: 0,
  15: 0,
};
for (let i = 1; i < 10982; i++) {
  const BEPSs = hexGridsMath.getPassBlocksBEPS(i);
  for (let k = 0; k < BEPSs.length; k++) {
    BEPSArr[BEPSs[k]]++;
    console.log(BEPSArr);
  }
}
