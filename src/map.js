const MOPNMath = require("./MOPNMath");

let hexes = MOPNMath.getCoordinateMapDiff({ x: 0, y: 0 }, { x: 3, y: -3 });

console.log("hexes", hexes, hexes.add.length, hexes.remove.length);
