const Migrations = artifacts.require("./Migrations.sol");
const MultisigWallet = artifacts.require('MultiSigWallet.sol');
const Factory = artifacts.require('Factory.sol');
const MultisigWalletFactory = artifacts.require('MultisigWalletFactory.sol')
const CarboDebtDummy = artifacts.require("./CarboDebtDummy.sol");
module.exports = function(deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(Factory);
    deployer.deploy(MultisigWalletFactory).then(function() {
        return deployer.deploy(CarboDebtDummy, MultisigWalletFactory.address);
    });
  //const args = process.argv.slice()
  //deployer.deploy(MultisigWalletFactory)
  //deployer.deploy(MultisigWallet, args[3].split(","), args[4])
  //console.log("Wallet deployed")
};