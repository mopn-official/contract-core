const axios = require('axios');
const MOPNMath = require("../simulator/MOPNMath");

const endpoint = 'https://api.thegraph.com/subgraphs/name/cyanface/mopn-' + hre.network.name;

async function fetchData(graphqlQuery) {
  const response = await axios({
    url: endpoint,
    method: 'post',
    data: graphqlQuery
  });
  return response.data;
}

async function getMoveToTilesAccounts(coordinate) {
  let tileaccounts = {};
  let coordinates = [];
  let tilesaccounts = [];

  coordinates[0] = coordinate.toString();
  coordinate++;
  for (let i = 0; i < 18; i++) {
    coordinates[i + 1] = coordinate.toString();
    if (i == 5) {
      coordinate += 10001;
    } else if (i < 5) {
      coordinate = MOPNMath.neighbor(coordinate, i);
    } else {
      coordinate = MOPNMath.neighbor(coordinate, Math.floor((i - 6) / 2));
    }
  }

  const graphqlQuery = {
    "operationName": "fetchCoordinates",
    "query": `query fetchCoordinates($id_in: [String!]) {
      coordinateDatas(where: {id_in: $id_in}) {
        id
        account {
          id
        }
      }
    }`,
    "variables": {
      "id_in": coordinates
    }
  };
  const coordinateDatas = await fetchData(graphqlQuery);
  for (let coordinateData of coordinateDatas.data.coordinateDatas) {
    if (coordinateData.account !== null) {
      tileaccounts[coordinateData.id] = coordinateData.account.id;
    }
  }

  coordinates.forEach(coordinate => {
    if (tileaccounts[coordinate]) {
      tilesaccounts.push(tileaccounts[coordinate]);
    } else {
      tilesaccounts.push(hre.ethers.constants.AddressZero);
    }
  });

  return tilesaccounts;
}

module.exports = {
  fetchData,
  getMoveToTilesAccounts
};
