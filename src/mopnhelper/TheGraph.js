const axios = require("axios");
const MOPNMath = require("../simulator/MOPNMath");
const { ZeroAddress } = require("ethers");

const endpoint = "https://api.thegraph.com/subgraphs/name/cyanface/mopn-" + hre.network.name;

async function fetchData(graphqlQuery) {
  const response = await axios({
    url: endpoint,
    method: "post",
    data: graphqlQuery,
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
    operationName: "fetchCoordinates",
    query: `query fetchCoordinates($id_in: [String!]) {
      coordinateDatas(where: {id_in: $id_in}) {
        id
        account {
          id
        }
      }
    }`,
    variables: {
      id_in: coordinates,
    },
  };
  const coordinateDatas = await fetchData(graphqlQuery);
  for (let coordinateData of coordinateDatas.data.coordinateDatas) {
    if (coordinateData.account !== null) {
      tileaccounts[coordinateData.id] = coordinateData.account.id;
    }
  }

  coordinates.forEach((coordinate) => {
    if (tileaccounts[coordinate]) {
      tilesaccounts.push(tileaccounts[coordinate]);
    } else {
      tilesaccounts.push(ZeroAddress);
    }
  });

  return tilesaccounts;
}

async function getMoveToTilesAccountsRich(coordinate) {
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
    operationName: "fetchCoordinates",
    query: `query fetchCoordinates($id_in: [String!]) {
      coordinateDatas(where: {id_in: $id_in}) {
        id
        account {
          id
          ContractAddress
        }
      }
    }`,
    variables: {
      id_in: coordinates,
    },
  };
  const coordinateDatas = await fetchData(graphqlQuery);
  for (let coordinateData of coordinateDatas.data.coordinateDatas) {
    if (coordinateData.account !== null) {
      tileaccounts[coordinateData.id] = {
        account: coordinateData.account.id,
        collection: coordinateData.account.ContractAddress,
      };
    }
  }

  coordinates.forEach((coordinate) => {
    if (tileaccounts[coordinate]) {
      tilesaccounts.push(tileaccounts[coordinate]);
    } else {
      tilesaccounts.push({
        account: ZeroAddress,
        collection: ZeroAddress,
      });
    }
  });

  return tilesaccounts;
}

async function getTilesAccountsRich(coordinates) {
  let tileaccounts = {};
  let tilesaccounts = [];
  const graphqlQuery = {
    operationName: "fetchCoordinates",
    query: `query fetchCoordinates($id_in: [String!]) {
      coordinateDatas(where: {id_in: $id_in}) {
        id
        account {
          id
          ContractAddress
        }
      }
    }`,
    variables: {
      id_in: coordinates,
    },
  };
  const coordinateDatas = await fetchData(graphqlQuery);
  for (let coordinateData of coordinateDatas.data.coordinateDatas) {
    if (coordinateData.account !== null) {
      tileaccounts[coordinateData.id] = {
        coordinate: coordinateData.id,
        account: coordinateData.account.id,
        collection: coordinateData.account.ContractAddress,
      };
    }
  }

  coordinates.forEach((coordinate) => {
    if (tileaccounts[coordinate]) {
      tilesaccounts.push(tileaccounts[coordinate]);
    } else {
      tilesaccounts.push({
        coordinate: coordinate,
        account: ZeroAddress,
        collection: ZeroAddress,
      });
    }
  });

  return tilesaccounts;
}

async function getCollectionOnMapAccounts(collection) {
  let accounts = [];

  const graphqlQuery = {
    operationName: "fetchCollectionOnMapAccounts",
    query: `query fetchCollectionOnMapAccounts($id: String!) {
      collectionData(id: $id) {
        accounts(where: {coordinate_not: null}){
          id
          coordinate{
            id
          }
          tokenId
        }
      }
    }`,
    variables: {
      id: collection,
    },
  };
  const accountsDatas = await fetchData(graphqlQuery);
  for (let account of accountsDatas.data.collectionData.accounts) {
    accounts.push({
      account: account.id,
      coordinate: account.coordinate.id,
      tokenId: account.tokenId,
    });
  }

  return accounts;
}

module.exports = {
  fetchData,
  getMoveToTilesAccounts,
  getMoveToTilesAccountsRich,
  getTilesAccountsRich,
  getCollectionOnMapAccounts,
};
