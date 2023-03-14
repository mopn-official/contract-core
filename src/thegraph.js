fetch("https://api.thegraph.com/subgraphs/name/cyanface/mopn", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    query: `
    query alliancesList{
        collectionDatas(orderBy: OnMapTiles, orderDirection: desc, first: 10, skip: 0) {
          AvatarNum
          COID
          OnMapMTAW
          OnMapNum
          OnMapTiles
          id
        }
      }
      `,
    variables: {
      now: new Date().toISOString(),
    },
  }),
})
  .then((res) => res.json())
  .then((result) => console.log(result.data));

fetch("https://api.thegraph.com/subgraphs/name/cyanface/mopn", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    query: `
    {
        collectionDatas(first: 100, ) {
          id
          COID
          OnMapNum
          OnMapMTAW
          OnMapTiles
          AvatarNum
        }
      }
      `,
    variables: {
      now: new Date().toISOString(),
    },
  }),
})
  .then((res) => res.json())
  .then((result) => console.log(result.data));
