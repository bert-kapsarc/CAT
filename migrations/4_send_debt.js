const CarboDebtDummy = artifacts.require("./CarboDebtDummy.sol");
const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");
module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboDebtDummy.deployed();
    let escrow = await instance.escroWallet(accounts[1], accounts[0]);
    let multisig = await MultiSigWallet.at(escrow);
    
    // confirm tx
    multisig.confirmTransaction(0, {from: accounts[0]}); 

    console.log(await multisig.transactions(0));  
    console.log(await instance.wallet(accounts[0]));    
}