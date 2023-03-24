const MOPNMath = require("./MOPNMath");

tileCoordinate = MOPNMath.coordinateXYToInt({ x: 0, y: 0 });
for (let i = 1; i <= 15; i++) {
  tileCoordinate++;
  for (let j = 0; j < 6; j++) {
    for (let k = 0; k < i; k++) {
      const LandId = MOPNMath.getTileLandId(tileCoordinate);

      const tile = MOPNMath.coordinateIntToXY(tileCoordinate);

      // Example usage:
      const coord = { q: tile.x, r: tile.y };
      const LandId1 = getLandNumber(coord);

      console.log(
        "coordinate:",
        MOPNMath.coordinateIntToXY(tileCoordinate),
        " LandId:",
        LandId,
        " LandId1:",
        LandId1
      );
      tileCoordinate = MOPNMath.neighbor(tileCoordinate, j);
    }
  }
}

function cubeDistance(a, b) {
  return (Math.abs(a.q - b.q) + Math.abs(a.r - b.r) + Math.abs(a.s - b.s)) / 2;
}

function axialToCube(axial) {
  const q = axial.q;
  const r = axial.r;
  const s = -q - r;
  return { q, r, s };
}

function getLandNumber(coord) {
  const origin = { q: 0, r: 0, s: 0 };
  const cubeCoord = axialToCube(coord);
  const distance = cubeDistance(origin, cubeCoord);

  let landIndex = 0;
  let radius = 0;

  while (distance > radius * 11) {
    landIndex += 6 * radius;
    radius++;
  }

  const angle = Math.atan2(cubeCoord.r - origin.r, cubeCoord.q - origin.q);
  const sector = Math.floor((angle + Math.PI / 6) / (Math.PI / 3));

  return landIndex + sector * radius + Math.floor(distance / 2);
}
