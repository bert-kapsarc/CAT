# CAT contract directory.

A smart contract and dApp for tracking emission responsibilities associated with the consumption of hydrocarbon resources. The Carbon Accounting Token.

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

* [Ganache](https://github.com/trufflesuite/ganache-cli/blob/master/README.md) - Personal Blockchain

```
npm install -g ganache-cli
```
[Or use the Gnache Gui](https://www.trufflesuite.com/docs/ganache/quickstart) 


## Installing

### Blockcahin (local)

To run a local blockchain with SACAT contract library

```
chmod u+x run.sh 
```
```
./run.sh
```

### Web API (local)

This is to run locally the API to access a version of the SACAT contract library (see build/) deployed to the Ethereum Ropsten testnet. The neccessary enviroment varibles are stored in /.env. Note these are public variables of the dapp, do not store private keys or sensitive info here.

```
npm install 
``` 
```
npm start 
``` 
[localhost](http://localhost:3002/)


## Remix

Too flatten all the contracts for easy import into solidity browser ([Remix](https://remix.ethereum.org/) )
```
truffle-flattener contracts/CarboTag.sol >> flatContract.sol
```
