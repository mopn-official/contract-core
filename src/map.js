const MOPNMath = require("./MOPNMath");

let hexes = MOPNMath.getCoordinateMapDiff({ x: 0, y: 0 }, { x: 2, y: 0 });

console.log("hexes", hexes, hexes.add.length, hexes.remove.length);
