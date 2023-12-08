const { BigNumber } = require("ethers");
const MOPNMath = require("./MOPNMath");
const db = require("./dblite");

const moveTo = async (account_address, collection_address, coordinate) => {
    let account = await db.getAccount(account_address);
    let collection = await db.getCollection(collection_address);

    if (await db.getTile(coordinate)) {
        errorexit("dst Occupied");
    }

    let linked;
    coordinate++;
    let tileAccount, tileAccountAddress;
    for (let i = 0; i < 18; i++) {
        tileAccountAddress = await db.getTile(coordinate);
        if (tileAccountAddress && tileAccountAddress != account_address) {
            tileAccount = await db.getAccount(tileAccountAddress);
            if (tileAccount.collection_address != collection_address) {
                errorexit(`tile ${coordinate} has enemy`);
            }
            linked = 1;
        }
        if (i == 5) {
            coordinate += 10001;
        } else if (i < 5) {
            coordinate = MOPNMath.neighbor(coordinate, i);
        } else {
            coordinate = MOPNMath.neighbor(coordinate, parseInt((i - 6) / 2));
        }
    }
    coordinate -= 2;

    if (!linked) {
        if (!(!collection || collection.onMapNum.isZero(0) || ((!account || account.coordinate > 0) && collection.onMapNum.eq(1)))) {
            errorexit("linked account missing");
        }
    }

    if (!collection) {
        await db.newCollection(collection_address);
        collection = await db.getCollection(collection_address);
    }

    let tileMOPNPoint = MOPNMath.getTileEAW(coordinate);
    if (!account) {
        await db.newAccount(account_address, collection_address, coordinate)
    } else {
        await db.updateAccount(account_address, 'coordinate', coordinate);
    }

    if (!account || account.coordinate == 0) {
        await db.updateCollection(collection_address, "onMapNum", collection.onMapNum.add(1));
    }

    let TotalMOPNPoint = await db.getMiningData("TotalMOPNPoint");
    if (account && account.coordinate > 0) {
        await db.setTile(account.coordinate, null);
        await db.setMiningData("TotalMOPNPoint", TotalMOPNPoint - MOPNMath.getTileEAW(account.coordinate) + tileMOPNPoint);
    } else {
        await db.setMiningData("TotalMOPNPoint", TotalMOPNPoint + tileMOPNPoint);
    }

    await db.setTile(coordinate, account_address);
};

const bomb = async (account_address, collection_address, coordinate, amount) => {
    let account = await db.getAccount(account_address);
    if (!account) {
        await db.newAccount(account_address, collection_address, 0)
        account = await db.getAccount(account_address);
    }

    let collection = await db.getCollection(collection_address);
    if (!collection) {
        await db.newCollection(collection_address);
        collection = await db.getCollection(collection_address);
    }

    if (account.bomb < amount) {
        errorexit('not enough bomb');
    }

    let TotalMOPNPoint = db.getMiningData("TotalMOPNPoint");
    let tileAccountAddress, tileCollection;
    let killed = 0;
    for (let i = 0; i < 7; i++) {
        tileAccountAddress = await db.getTile(coordinate);
        if (tileAccountAddress && tileAccountAddress != account_address) {
            tileAccount = await db.getAccount(tileAccountAddress);
            if (tileAccount.shield < amount) {
                tileCollection = await db.getCollection(tileAccount.collection_address);
                TotalMOPNPoint -= MOPNMath.getTileEAW(coordinate) + tileCollection.collectionPoint + tileCollection.buffPoint;
                db.updateAccount(tileAccountAddress, 'coordinate', 0);
                db.updateAccount(tileAccountAddress, 'shield', 0);
                db.setTile(coordinate, null);
                db.updateCollection(tileAccount.collection_address, 'onMapNum', tileCollection.onMapNum - 1);
                killed++;
            } else {
                db.updateAccount(tileAccountAddress, 'shield', tileAccount.shield - amount);
            }

        }

        if (i == 0) {
            coordinate++;
        } else {
            coordinate = MOPNMath.neighbor(coordinate, i - 1);
        }
    }

    db.setMiningData("TotalMOPNPoint", TotalMOPNPoint);
};

const buybomb = async (account_address, amount) => {
    let account = await db.getAccount(account_address);
    if (!account) {
        await db.newAccount(account_address, collection_address, 0)
        account = await db.getAccount(account_address);
    }

    let auction = await db.getRunningAuction();
    if (auction.sold + amount > 10) {
        errorexit("round out of stack");
    }
    let price = await getBombPrice(auction.starttimestamp);
    let totalprice = price * amount;
    if (account.balance < totalprice) {
        errorexit("not enough mt");
    }

    await db.updateAccount(account_address, 'balance', account.balance - totalprice);
    await db.updateAccount(account_address, 'bomb', amount);
    await db.updateAuction(auction.id, auction.sold + amount);
    await db.addAuctionSell(auction.id, account_address, amount, price);

    if (auction.sold + amount == 10) {
        await db.newAuction();
        const sells = await db.getAuctionSells(auction.id);
        for (const sell of sells) {
            if (sell.dealprice > price) {
                const sellAccount = await db.getAccount(sell.account_address);
                db.updateAccount(sell.account_address, 'balance', (sellAccount.balance + (sell.dealprice - price) * sell.amount));
            }
        }
    }

    console.log(`bought ${amount} bomb at price ${price}`);
};

const stakeMT = async (account_address, collection_address, amount) => {
    amount = BigNumber.from(amount);
    let account = await db.getAccount(account_address);
    if (!account) {
        await db.newAccount(account_address, "", 0)
        account = await db.getAccount(account_address);
    }

    let collection = await db.getCollection(collection_address);
    if (!collection) {
        await db.newCollection(collection_address);
        collection = await db.getCollection(collection_address);
    }

    if (account.balance.lt(amount)) {
        errorexit("not enough mt");
    }

    await db.updateAccount(account_address, 'balance', account.balance.sub(amount));

    let collectionPoint = collection.balance.add(amount).div(BigNumber.from(100000000));
    await db.updateCollection(collection_address, 'collectionPoint', collectionPoint);
    await db.updateCollection(collection_address, 'balance', collection.balance.add(amount));

    let TotalMOPNPoint = BigNumber.from(await db.getMiningData("TotalMOPNPoint"));
    TotalMOPNPoint = TotalMOPNPoint.add(collectionPoint.sub(collection.collectionPoint)).mul(collection.onMapNum);
    await db.setMiningData("TotalMOPNPoint", TotalMOPNPoint.toString());

    let mvtbalance;
    if (collection.mvtbalance.isZero()) {
        mvtbalance = amount.mul(BigNumber.from(1000000000000));
    } else {
        mvtbalance = amount.mul(collection.mvtbalance).div(collection.balance);
    }
    await db.updateCollection(collection_address, 'mvtbalance', collection.mvtbalance.add(mvtbalance));
    await db.setAccountStake(account_address, collection_address, (await db.getAccountStake(account_address, collection_address)).add(mvtbalance));
};

const unstakeMT = async (account_address, collection_address, mvtbalance) => {
    let account = await db.getAccount(account_address);
    if (!account) {
        await db.newAccount(account_address, collection_address, 0)
        account = await db.getAccount(account_address);
    }

    let collection = await db.getCollection(collection_address);
    if (!collection) {
        await db.newCollection(collection_address);
        collection = await db.getCollection(collection_address);
    }

    let accountmvtbalance = await db.getAccountStake(account_address, collection_address);
    if (accountmvtbalance.lt(mvtbalance)) {
        errorexit("not enough mvt");
    }

    let amount = collection.balance.mul(mvtbalance).div(collection.mvtbalance);

    await db.updateAccount(account_address, 'balance', account.balance.add(amount));
    await db.setAccountStake(account_address, collection_address, accountmvtbalance.sub(mvtbalance));
    await db.updateCollection(collection_address, 'balance', collection.balance.sub(amount));
    await db.updateCollection(collection_address, 'mvtbalance', collection.mvtbalance.sub(mvtbalance));

    let collectionPoint = collection.balance.sub(amount).div(BigNumber.from(100000000));
    await db.updateCollection(collection_address, 'collectionPoint', collectionPoint);
    let TotalMOPNPoint = BigNumber.from(await db.getMiningData("TotalMOPNPoint"));
    TotalMOPNPoint = TotalMOPNPoint.sub(collection.collectionPoint.sub(collectionPoint).mul(collection.onMapNum));
    await db.setMiningData("TotalMOPNPoint", TotalMOPNPoint.toString());
};

const claimAccountsMT = async (wallet, accounts) => {
    let walletaccount = await db.getAccount(wallet);
    if (!walletaccount) {
        await db.newAccount(wallet, null, 0)
        walletaccount = await db.getAccount(wallet);
    }

    let totalamount = BigNumber.from(0);
    for (const accountAddress of accounts) {
        const account = await db.getAccount(accountAddress);
        if (!account.balance.isZero()) {
            await db.updateAccount(account.account_address, 'balance', BigNumber.from(0));
            totalamount = totalamount.add(account.balance);
        }
    }

    if (!totalamount.isZero()) {
        await db.updateAccount(wallet, 'balance', walletaccount.balance.add(totalamount));
    }
};

const payAll = async () => {
    const currentBlock = BigNumber.from(await db.getMiningData("currentBlock"));
    const lastTickBlock = BigNumber.from(await db.getMiningData("lastTickBlock"));
    if (currentBlock.gt(lastTickBlock)) {
        let TotalMOPNPoint = BigNumber.from(await db.getMiningData("TotalMOPNPoint"));
        const produced = currentBlock.sub(lastTickBlock).mul(BigNumber.from(60000000));
        const collections = {};
        const accounts = await db.getMiningAccounts();
        for (const account of accounts) {
            if (!collections[account.collection_address]) {
                collections[account.collection_address] = await db.getCollection(account.collection_address);
            }

            const income = BigNumber.from(MOPNMath.getTileEAW(account.coordinate)).add(collections[account.collection_address].buffPoint)
                .add(collections[account.collection_address].collectionPoint).mul(produced).div(TotalMOPNPoint);

            await db.updateAccount(account.account_address, 'balance', account.balance.add(income.mul(BigNumber.from(9)).div(BigNumber.from(10))));
            collections[account.collection_address].balance = collections[account.collection_address].balance.add(income.mul(BigNumber.from(5)).div(BigNumber.from(100)));
            await db.updateCollection(account.collection_address, 'balance', collections[account.collection_address].balance);
        }
        await db.setMiningData("lastTickBlock", currentBlock.toString());
    }
};

const getBombPrice = async (starttimestamp) => {
    return parseInt(100000000000 * Math.pow(0.99, Math.floor((Math.floor(Date.now() / 1000) - starttimestamp) / 60)));
};

const getBlockNumber = async () => {
    return await db.getMiningData("currentBlock");
}

const reset = async () => {
    await db.deleteTable();
    await db.createTable();
    await db.newAuction();
    await db.setMiningData("lastTickBlock", 0);
    await db.setMiningData("currentBlock", 0);
}

const mine = async (num) => {
    const currentBlock = await db.getMiningData("currentBlock");
    await db.setMiningData("currentBlock", currentBlock + num);
}

function errorexit(error) {
    throw error
}

module.exports = {
    reset, mine, moveTo, bomb, buybomb, stakeMT,
    unstakeMT, claimAccountsMT, payAll, getBombPrice, getBlockNumber, errorexit, db
};

