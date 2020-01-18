//const web3 = new Web3(provider, null, { transactionConfirmationBlocks: 1 });
//var Web3 = require('web3');
//const ganache = require("ganache-core");
//var balance =[];
//for(let i = 0; i < 10; i++){
//    balance[i]={balance: 1e18.toString(16)};
//}
//const web3 = new Web3(ganache.provider(balance));

const Migrations = artifacts.require("./Migrations.sol");
const MultisigWallet = artifacts.require('MultiSigWallet.sol');
const Factory = artifacts.require('Factory.sol');
const MultisigWalletFactory = artifacts.require('MultisigWalletFactory.sol')
const CarboTag = artifacts.require("./CarboTag.sol");
module.exports = function(deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(Factory);
    deployer.deploy(MultisigWalletFactory).then(function() {
        return deployer.deploy(CarboTag, MultisigWalletFactory.address);
    });
  //const args = process.argv.slice()
  //deployer.deploy(MultisigWalletFactory)
  //deployer.deploy(MultisigWallet, args[3].split(","), args[4])
  //console.log("Wallet deployed")
};