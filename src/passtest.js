const MOPNMath = require("./MOPNMath");

tileCoordinate = MOPNMath.coordinateXYToInt({ x: 0, y: 0 });
for (let i = 1; i <= 15; i++) {
  tileCoordinate++;
  for (let j = 0; j < 6; j++) {
    for (let k = 0; k < i; k++) {
      const PassId = MOPNMath.getTilePassId(tileCoordinate);

      console.log(
        "coordinate:",
        MOPNMath.coordinateIntToXY(tileCoordinate),
        " PassId:",
        PassId,
        " openstatus:",
        MOPNMath.checkPassIdOpen(PassId, 1),
        " tile Energy allocation Weight:",
        MOPNMath.getTileEAW(tileCoordinate)
      );
      tileCoordinate = MOPNMath.neighbor(tileCoordinate, j);
    }
  }
}
