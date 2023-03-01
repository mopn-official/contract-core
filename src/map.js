const MOPNMath = require("./MOPNMath");

let hexes = MOPNMath.getCoordinateMapDiff({ x: 0, y: 0 }, { x: 1, y: 0 });

console.log("hexes", hexes);
