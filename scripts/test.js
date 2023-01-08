const axios = require("axios");
const { parse } = require("json2csv");

async function getdata() {
  let arr = [];
  let offset = 0;
  while (true) {
    if (offset >= 600) break;
    try {
      const response = await axios.get(
        "https://data-api.nftgo.io/eth/v1/market/rank/collection/all",
        {
          headers: {
            accept: "application/json",
            "X-API-KEY": "a2843d0d-cd1c-45f2-8974-abf87bc5894d",
          },
          params: {
            offset: offset,
            limit: 50,
            by: "market_cap",
            asc: false,
            with_rarity: true,
          },
        }
      );
      console.log(offset);
      for (let i = 0; i < response.data.collections.length; i++) {
        arr.push({
          name: response.data.collections[i].name,
          // market_cap_eth: response.data.collections[i].market_cap_eth,
          // floor_price_eth: response.data.collections[i].floor_price_eth,
          // holder_num: response.data.collections[i].holder_num,
          // opensea_url: response.data.collections[i].opensea_url,
        });
      }
      offset += 50;
    } catch (error) {
      console.error(error);
    }
  }
  return arr;
}

getdata().then((res) => {
  const csv = parse(res);
  console.log(csv);
});
