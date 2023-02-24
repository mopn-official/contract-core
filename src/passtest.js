const MOPNMath = require("./MOPNMath");

tileCoordinate = MOPNMath.coordinateXYToInt({ x: 0, y: 0 });
for (let i = 1; i <= 15; i++) {
  tileCoordinate++;
  for (let j = 0; j < 6; j++) {
    for (let k = 0; k < i; k++) {
      const LandId = MOPNMath.getTileLandId(tileCoordinate);

      console.log(
        "coordinate:",
        MOPNMath.coordinateIntToXY(tileCoordinate),
        " LandId:",
        LandId,
        " openstatus:",
        MOPNMath.checkLandIdOpen(LandId, 1),
        " tile Energy allocation Weight:",
        MOPNMath.getTileEAW(tileCoordinate)
      );
      tileCoordinate = MOPNMath.neighbor(tileCoordinate, j);
    }
  }
}

for (let i = 1; i <= 100; i++) {
  console.log(MOPNMath.COIDToColor(i));
}
