const { BigNumber } = require("ethers");

// db.js
const sqlite3 = require("sqlite3").verbose();

const db = new sqlite3.Database(__dirname + "/data/mopnsimulator.db", (err) => {
  if (err) {
    console.error(err.message);
  }
  process.env.DEBUG && console.log("Connected to the mopnsimulator database.");
});

const createTileTable = () => {
  const query = `
  CREATE TABLE IF NOT EXISTS tiles (
    id INTEGER PRIMARY KEY,
    account_address TEXT
  );`;
  const indexQuery = `CREATE INDEX IF NOT EXISTS account_address ON "tiles" ("account_address");`;

  return new Promise((resolve, reject) => {
    db.run(query, (err) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        process.env.DEBUG && console.log("tiles table created");
        db.run(indexQuery, (err) => {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            process.env.DEBUG && console.log("tiles index created");
            resolve();
          }
        });
      }
    });
  });
};

const createAccountsTable = () => {
  const query = `
  CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_address TEXT,
    collection_address TEXT,
    coordinate INTEGER DEFAULT 0,
    balance TEXT,
    bomb INTEGER DEFAULT 0,
    shield INTEGER DEFAULT 0
  );`;
  const indexQuery = `CREATE UNIQUE INDEX IF NOT EXISTS account_address ON "accounts" ("account_address");`;

  return new Promise((resolve, reject) => {
    db.run(query, (err) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        process.env.DEBUG && console.log("accounts table created");
        db.run(indexQuery, (err) => {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            process.env.DEBUG && console.log("accounts index created");
            resolve();
          }
        });
      }
    });
  });
};

const createCollectionsTable = () => {
  const query = `
  CREATE TABLE IF NOT EXISTS collections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    collection_address TEXT,
    onMapNum INTEGER DEFAULT 0,
    buffPoint INTEGER DEFAULT 0,
    collectionPoint INTEGER DEFAULT 0,
    balance TEXT,
    mvtbalance TEXT
  );`;
  const indexQuery = `CREATE UNIQUE INDEX IF NOT EXISTS collection_address ON "collections" ("collection_address");`;

  return new Promise((resolve, reject) => {
    db.run(query, (err) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        process.env.DEBUG && console.log("collections table created");
        db.run(indexQuery, (err) => {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            process.env.DEBUG && console.log("collections index created");
            resolve();
          }
        });
      }
    });
  });
};

const createMiningDataTable = () => {
  const query = `
  CREATE TABLE IF NOT EXISTS miningdata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT,
    value INTEGER DEFAULT 0
  );`;
  const indexQuery = `CREATE UNIQUE INDEX IF NOT EXISTS key ON "miningdata" ("key");`;

  return new Promise((resolve, reject) => {
    db.run(query, (err) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        process.env.DEBUG && console.log("miningdata table created");
        db.run(indexQuery, (err) => {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            process.env.DEBUG && console.log("miningdata index created");
            resolve();
          }
        });
      }
    });
  });
};

const createAuctionTable = () => {
  const query = `
  CREATE TABLE IF NOT EXISTS auctions (
    id INTEGER PRIMARY KEY,
    starttimestamp INTEGER,
    sold INTEGER
  );`;

  return new Promise((resolve, reject) => {
    db.run(query, (err) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        process.env.DEBUG && console.log("auctions table created");
        resolve();
      }
    });
  });
};

const createAuctionSellTable = () => {
  const query = `
  CREATE TABLE IF NOT EXISTS auctionsell (
    id INTEGER PRIMARY KEY,
    auction_id INTEGER DEFAULT 0,
    account_address TEXT,
    amount INTEGER DEFAULT 0,
    dealprice INTEGER DEFAULT 0
  );`;
  const indexQuery = `CREATE INDEX IF NOT EXISTS auction_id ON "auctionsell" ("auction_id");`;

  return new Promise((resolve, reject) => {
    db.run(query, (err) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        process.env.DEBUG && console.log("auctionsell table created");
        db.run(indexQuery, (err) => {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            process.env.DEBUG && console.log("auctionsell index created");
            resolve();
          }
        });
      }
    });
  });
};

const createAccountStakeTable = () => {
  const query = `
  CREATE TABLE IF NOT EXISTS accountstake (
    id INTEGER PRIMARY KEY,
    account_address TEXT,
    collection_address TEXT,
    mvtbalance TEXT
  );`;
  const indexQuery = `CREATE INDEX IF NOT EXISTS account_collection ON "accountstake" ("account_address", "collection_address");`;

  return new Promise((resolve, reject) => {
    db.run(query, (err) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        process.env.DEBUG && console.log("accountstake table created");
        db.run(indexQuery, (err) => {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            process.env.DEBUG && console.log("accountstake index created");
            resolve();
          }
        });
      }
    });
  });
};

const createTable = async () => {
  await createTileTable();
  await createAccountsTable();
  await createCollectionsTable();
  await createMiningDataTable();
  await createAuctionTable();
  await createAuctionSellTable();
  await createAccountStakeTable();
};

const deleteTable = async () => {
  return new Promise((resolve, reject) => {
    db.run("DROP TABLE IF EXISTS accounts", (err) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        db.run("DROP TABLE IF EXISTS collections", (err) => {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            db.run("DROP TABLE IF EXISTS tiles", (err) => {
              if (err) {
                console.error(err.message);
                reject(err);
              } else {
                db.run("DROP TABLE IF EXISTS miningdata", (err) => {
                  if (err) {
                    console.error(err.message);
                    reject(err);
                  } else {
                    db.run("DROP TABLE IF EXISTS auctions", (err) => {
                      if (err) {
                        console.error(err.message);
                        reject(err);
                      } else {
                        db.run("DROP TABLE IF EXISTS auctionsell", (err) => {
                          if (err) {
                            console.error(err.message);
                            reject(err);
                          } else {
                            db.run("DROP TABLE IF EXISTS accountstake", (err) => {
                              if (err) {
                                console.error(err.message);
                                reject(err);
                              } else {
                                resolve();
                              }
                            });
                          }
                        });
                      }
                    });
                  }
                });
              }
            });
          }
        });
      }
    });
  });
};

const newAccount = (
  accountAddress,
  contractAddress,
  coordinate,
) => {
  const query = `
  INSERT OR IGNORE INTO accounts (account_address, collection_address, coordinate)
  VALUES (?, ?, ?);`;

  return new Promise((resolve, reject) => {
    db.run(
      query,
      [
        accountAddress,
        contractAddress,
        coordinate,
      ],
      function (err) {
        if (err) {
          console.error(err.message);
          reject(err);
        } else {
          process.env.DEBUG && console.log(`New Account added: ${accountAddress}`);
          resolve(this.lastID);
        }
      }
    );
  });
};

const getAccount = (accountAddress) => {
  const query = `
    SELECT * FROM accounts WHERE account_address = ?;`;

  return new Promise((resolve, reject) => {
    db.get(query, [accountAddress], (err, row) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        if (row !== undefined) {
          row.balance = BigNumber.from(row.balance == null ? 0 : row.balance);
        }
        resolve(row);
      }
    });
  });
};

const updateAccount = (accountAddress, key, value) => {
  const query = `UPDATE accounts SET ${key} = ? WHERE account_address = ?`;
  return new Promise((resolve, reject) => {
    db.run(
      query,
      [
        key == 'balance' ? value.toString() : value,
        accountAddress,
      ],
      function (err) {
        if (err) {
          console.error(err.message);
          reject(err);
        } else {
          process.env.DEBUG && console.log(`Updated account ${key} => ${value} for address: ${accountAddress}`);
          resolve(this.changes);
        }
      }
    );
  });
};

const getMiningAccounts = () => {
  const query = `
    SELECT * FROM accounts WHERE coordinate > 0;`;

  return new Promise((resolve, reject) => {
    db.all(query, (err, rows) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        for (let i = 0; i < rows.length; i++) {
          rows[i].balance = BigNumber.from(rows[i].balance == null ? 0 : rows[i].balance);
        }
        resolve(rows);
      }
    });
  });
};

const newCollection = (
  contractAddress
) => {
  const query = `
  INSERT OR IGNORE INTO collections (collection_address)
  VALUES (?);`;

  return new Promise((resolve, reject) => {
    db.run(
      query,
      [
        contractAddress
      ],
      function (err) {
        if (err) {
          console.error(err.message);
          reject(err);
        } else {
          process.env.DEBUG && console.log(`New Collection added: ${contractAddress}`);
          resolve(this.lastID);
        }
      }
    );
  });
};

const getCollection = (collectionAddress) => {
  const query = `
    SELECT * FROM collections WHERE collection_address = ?;`;

  return new Promise((resolve, reject) => {
    db.get(query, [collectionAddress], (err, row) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        if (row !== undefined) {
          row.onMapNum = BigNumber.from(row.onMapNum);
          row.buffPoint = BigNumber.from(row.buffPoint);
          row.collectionPoint = BigNumber.from(row.collectionPoint);
          row.balance = BigNumber.from(row.balance == null ? 0 : row.balance);
          row.mvtbalance = BigNumber.from(row.mvtbalance == null ? 0 : row.mvtbalance);
        }
        resolve(row);
      }
    });
  });
};

const updateCollection = (collectionAddress, key, value) => {
  const query = `UPDATE collections SET ${key} = ? WHERE collection_address = ?`;
  return new Promise((resolve, reject) => {
    db.run(
      query,
      [
        value.toString(),
        collectionAddress,
      ],
      function (err) {
        if (err) {
          console.error(err.message);
          reject(err);
        } else {
          process.env.DEBUG && console.log(`Updated collection ${key} => ${value} for address: ${collectionAddress}`);
          resolve(this.changes);
        }
      }
    );
  });
};

const setMiningData = async (
  key,
  value
) => {
  const query = `
    SELECT * FROM miningdata WHERE key = ?;`;

  return new Promise((resolve, reject) => {
    db.get(query, [key], (err, row) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        if (row === undefined) {
          const query = `
          INSERT INTO miningdata (key, value)
          VALUES (?, ?);`;
          db.run(
            query,
            [
              key,
              value
            ],
            function (err) {
              if (err) {
                console.error(err.message);
                reject(err);
              } else {
                process.env.DEBUG && console.log(`${key} seted: ${value}`);
                resolve(this.lastID);
              }
            }
          );
        } else {
          const query = `UPDATE miningdata SET value = ? WHERE key = ?`;
          db.run(
            query,
            [
              value,
              key,
            ],
            function (err) {
              if (err) {
                console.error(err.message);
                reject(err);
              } else {
                process.env.DEBUG && console.log(`${key} seted: ${value}`);
                resolve(this.changes);
              }
            }
          );
        }
      }
    });
  });
};

const getMiningData = (key) => {
  const query = `
    SELECT * FROM miningdata WHERE key = ?;`;

  return new Promise((resolve, reject) => {
    db.get(query, [key], (err, row) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        resolve(row !== undefined ? row.value : 0);
      }
    });
  });
};

const setTile = async (
  coordinate,
  account_address
) => {
  if (await getTile(coordinate)) {
    const query = `UPDATE tiles SET account_address = ? WHERE id = ?`;
    return new Promise((resolve, reject) => {
      db.run(
        query,
        [
          account_address,
          coordinate,
        ],
        function (err) {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            process.env.DEBUG && console.log(`set tile ${coordinate} ${account_address}`);
            resolve(this.changes);
          }
        }
      );
    });
  } else {
    const query = `
    INSERT INTO tiles (id, account_address)
    VALUES (?, ?);`;

    return new Promise((resolve, reject) => {
      db.run(
        query,
        [
          coordinate,
          account_address
        ],
        function (err) {
          if (err) {
            console.error(err.message);
            reject(err);
          } else {
            process.env.DEBUG && console.log(`insert tile ${coordinate} ${account_address}`);
            resolve(this.lastID);
          }
        }
      );
    });
  }
};

const getTile = (coordinate) => {
  const query = `
    SELECT * FROM tiles WHERE id = ?;`;

  return new Promise((resolve, reject) => {
    db.get(query, [coordinate], (err, row) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        resolve(row ? row.account_address : undefined);
      }
    });
  });
};

const getRunningAuction = () => {
  const query = `
    SELECT * FROM auctions ORDER BY id DESC LIMIT 1;`;

  return new Promise((resolve, reject) => {
    db.get(query, (err, row) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        resolve(row);
      }
    });
  });
};

const updateAuction = (id, sold) => {
  const query = `UPDATE collections SET sold = ? WHERE id = ?`;
  return new Promise((resolve, reject) => {
    db.run(
      query,
      [
        sold,
        id,
      ],
      function (err) {
        if (err) {
          console.error(err.message);
          reject(err);
        } else {
          process.env.DEBUG && console.log(`Updated auction sold => ${sold} for id: ${id}`);
          resolve(this.changes);
        }
      }
    );
  });
};

const newAuction = () => {
  const query = `
  INSERT OR IGNORE INTO auctions (starttimestamp)
  VALUES (?);`;

  return new Promise((resolve, reject) => {
    db.run(
      query,
      [
        Math.floor(Date.now() / 1000)
      ],
      function (err) {
        if (err) {
          console.error(err.message);
          reject(err);
        } else {
          process.env.DEBUG && console.log(`New auction added: ${this.lastID}`);
          resolve(this.lastID);
        }
      }
    );
  });
};

const addAuctionSell = (auction_id, account_address, amount, dealprice) => {
  const query = `
  INSERT OR IGNORE INTO auctionsell (auction_id, account_address, amount, dealprice)
  VALUES (?,?,?,?);`;

  return new Promise((resolve, reject) => {
    db.run(
      query,
      [
        Math.floor(Date.now() / 1000)
      ],
      function (err) {
        if (err) {
          console.error(err.message);
          reject(err);
        } else {
          process.env.DEBUG && console.log(`New auctionsell added: ${this.lastID}`);
          resolve(this.lastID);
        }
      }
    );
  });
};

const getAuctionSells = (id) => {
  const query = `
    SELECT * FROM auctionsell WHERE auction_id = ? ORDER BY id DESC;`;

  return new Promise((resolve, reject) => {
    db.all(query, (err, rows) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        resolve(rows);
      }
    });
  });
};

const getAccountStake = (account_address, collection_address) => {
  const query = `
    SELECT * FROM accountstake WHERE account_address = ? AND collection_address = ?;`;

  return new Promise((resolve, reject) => {
    db.get(query, [account_address, collection_address], (err, row) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        resolve(row == undefined ? BigNumber.from(0) : BigNumber.from(row.mvtbalance));
      }
    });
  });
};

const setAccountStake = (accountAddress, collectionAddress, mvtbalance) => {
  const query = `
    SELECT * FROM accountstake WHERE account_address = ? AND collection_address = ?;`;

  return new Promise((resolve, reject) => {
    db.get(query, [accountAddress, collectionAddress], (err, row) => {
      if (err) {
        console.error(err.message);
        reject(err);
      } else {
        if (row == undefined) {
          const query = `INSERT OR IGNORE INTO accountstake (account_address, collection_address, mvtbalance) VALUES (?,?,?);`;
          db.run(
            query,
            [
              accountAddress, collectionAddress, mvtbalance.toString()
            ],
            function (err) {
              if (err) {
                console.error(err.message);
                reject(err);
              } else {
                process.env.DEBUG && console.log(`new accountstake seted: ${accountAddress} ${collectionAddress} ${mvtbalance}`);
                resolve();
              }
            }
          );
        } else {
          const query = `UPDATE accountstake SET mvtbalance = ? WHERE account_address = ? AND collection_address = ?`;
          db.run(
            query,
            [
              mvtbalance.toString(),
              accountAddress,
              collectionAddress
            ],
            function (err) {
              if (err) {
                console.error(err.message);
                reject(err);
              } else {
                process.env.DEBUG && console.log(`accountstake seted: ${accountAddress} ${collectionAddress} ${mvtbalance}`);
                resolve();
              }
            }
          );
        }
      }
    });
  });
}


module.exports = {
  db,
  createTable,
  deleteTable,
  newAccount,
  getAccount,
  updateAccount,
  newCollection,
  getCollection,
  updateCollection,
  setMiningData,
  getMiningData,
  setTile,
  getTile,
  getMiningAccounts,
  getRunningAuction,
  updateAuction,
  newAuction,
  getAuctionSells,
  addAuctionSell,
  getAccountStake,
  setAccountStake
};
