const hexGridsMath = require("./MOPNMath");

tileCoordinate = hexGridsMath.coordinateXYToInt({ x: 0, y: 0 });
for (let i = 1; i <= 15; i++) {
  tileCoordinate++;
  for (let j = 0; j < 6; j++) {
    for (let k = 0; k < i; k++) {
      const PassId = hexGridsMath.getTilePassId(tileCoordinate);

      console.log(
        "coordinate:",
        hexGridsMath.coordinateIntToXY(tileCoordinate),
        " PassId:",
        PassId,
        " openstatus:",
        hexGridsMath.checkPassIdOpen(PassId, 1),
        " tile Energy allocation Weight:",
        hexGridsMath.getTileEAW(tileCoordinate)
      );
      tileCoordinate = hexGridsMath.neighbor(tileCoordinate, j);
    }
  }
}
