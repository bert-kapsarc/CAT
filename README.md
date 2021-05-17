# The Carbon Accounting Token (CAT) contract directory.

A smart contract library and dApp for tracking emission inventories across hydrocarbon fuel supply chains. 

*This project is curretnly undegoing restructuring. Including building separate project stream :*

1. CAT network for private transfers and tracking of emission inventories by large companies *(private network, e.g., Besu or Fabric)*
2. CAT dapp SDK for interactng with the CAT network *(currently using node.js)*.
3. Carbon organizational governance (COG) identity netowor  for registering and managing the identities/roles of carbon management organizations / service providers. *Use a public/permissionsed identity network, e.g., Indy*.
4. COG contracts for auditing private emission inventories (private network), registering carbon managment assets and exposing these to public carbon token programs (public network). E.g., emission certificates and carbon offset credits.

## Getting Started

### Prerequisites
* [Solidity](https://solidity.readthedocs.io/en/v0.5.3/installing-solidity.html) - Smart contract compiler

```
npm install -g solc
```
* [Truffle](https://www.trufflesuite.com/docs/truffle/getting-started/installation) - Development toolkit
```
npm install -g truffle
```

## Blockcahin network setup 

### Setup local development network
Compile any changes to contract library
```truffle compile```

**Use Ganache**
```
npm install -g ganache-cli
```
```
./run.sh 
```
If Ganache app already running
```truffle migrate --network development ```

*See `truffle-config.js` for network config*

**Using local Besu network**
[e.g. Besu quorum-test-network](https://besu.hyperledger.org/en/stable/Tutorials/Developer-Quickstart/).

This is to deploy on private/permissioned EVM using POA consensus.

```
npx quorum-dev-quickstart
```
```
cd quorum-test-network
```
*Start nodes as docker containers*
```
./run.sh
```
See `README.md` for futher instructions and node management.

To deploy local network
```
truffle migrate --network local
```

### For public network using an ethereum testnet (Ropsten)

Set INFURA_ROPSTEN and correspoinding PRIVATE_KEY envrionment variables in `.env` from avaiable wallet
```
truffle migrate --network ropsten
```
See `truffle-config.js` to configure a different network

Or flatten contract 
```
truffle-flattener contracts/CAT.sol >> flatContract.sol
```
and compile/deploy CAT contract using [Remix](https://remix.ethereum.org)
Use the following MultisigWalletFactory (mswfactory) address as input (used to generate escrow contracts).
`0x0A4aC8cf056b464a4c1737293bc1E52eC469F09A`
Latest CAT contract address is
`0xFC6E33bBE510BDAe4737809Aec5C60B653D0E8bE`

## Run dapp
Set CAT_ADDR (CAT contract address) in `dapp/.env`
Set NETWORK_URL .env variable to desired network (e.g., ropsten, ganache, besu)

```
npm install
```
```
npm start
```

*if running a local network navigate to*
[localhost](http://localhost:3002/)

