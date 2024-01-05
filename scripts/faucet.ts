import { TatumSDK, Network, Ethereum } from "@tatumio/tatum";

const tatum = await TatumSDK.init<Ethereum>({
  network: Network.ETHEREUM_SEPOLIA,
  apiKey: {
    v4: "t-657ab486d0705c001ce96f2b-7a07cdd2c48f47c5bb006f55",
  },
});

const result = await tatum.faucet.fund("0x712e3a792c974b3e3dbe41229ad4290791c75a82");
await tatum.destroy();
