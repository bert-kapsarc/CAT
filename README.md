# CarboDebt conract directory.

A smart contract/ dApp for tracking  emission responsabilities associated with the consumption of hydrocarbon resources. 

Non-linear allocation agreements -

Debt is a linear agreement .. this is more of an allocation agreement

Not a carbon credit program. It is a debt (?) contract. The pupose of the contracts are to provide a scientifically rigorous account of where emission debt is coming from and how it is being traded.

Debt holder can pay a fee to abate their emissions through an approved carbon sinker, such as sequestration, reforestation. Sinkers certify the CarboDebt to issue CarboGold, converting it into a neutral emission: an amount of carbon removed from the atmosphere based on agreements between debt participants. The value of carbon gold could reflect the marginal cost of the carbon sinker, or some perceived value that a producer/consumer may be willing to pay to receive CarboGold rather than CarboDebt, as proof of offset emissions.

## Getting Started

We summarize the function of the carbo-debt contract in the 5 points below.

1.  anyone can create a carbo debt wallet to issue carbon budget attributed to production ownership of commodity with a known energy content/intput 

2.  Each participant in a contract is defined by a given decentralized identifier (DiD)
    supplier (hydrocarbon producers). Usually the first creators of carbon debt
    consumer (can voluntarily create debt contract if not initiated further upstream)
    carbon sinker (sequestration, reforestation, ,,,)

    sinkers also play the role of converting Carbon debt into carbon gold ...

3.  Can request to send/receive carbo debt from a counter-party, with the all parties approval (signature)

4.  The debt contract is transferred on 
        sale of commodity, 
        paying sinker to offload the responsability

5.  Contract participants can fund contract use by carbon manager to off-take the debt

6.  Recipients can decline to receive the debt, and contract may communicate the additional charge for retaining the debt. Or sender cna offer the option to receive CarboGold in exchange for an additional fee.

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
* [Or use the Gnache Gui](https://www.trufflesuite.com/docs/ganache/quickstart) 


### Installing

Not much yet

```
chmod u+x run.sh 
```
```
./run.sh
```
 
Too flatten all the contracts fro easy import into solidity browser ([Remix](https://remix.ethereum.org/) )
```
truffle-flattener contracts/CarboTag.sol >> flatContract.sol
```




See below a list of proposed Carbon credit schemes (competitors?)

https://medium.com/@robertgreenfieldiv/blockchain-enabled-carbon-credit-markets-1a195520f0e1

https://medium.com/@rzurrer/the-carbon-token-ecosystem-white-paper-a-decentralized-p2p-self-organizing-consensus-mechanism-and-aa218bdeeb64

https://drive.google.com/file/d/1D4jmU_TQ3TnEaBhMNpM-phs1tZvRwttn/view
